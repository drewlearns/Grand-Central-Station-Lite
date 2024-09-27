const { Decimal } = require('decimal.js');
const { PrismaClient } = require('@prisma/client');
const { LambdaClient, InvokeCommand } = require('@aws-sdk/client-lambda');
const { SecretsManagerClient, CreateSecretCommand } = require('@aws-sdk/client-secrets-manager');
const { v4: uuidv4 } = require('uuid');
const { format, fromUnixTime } = require('date-fns');

const prisma = new PrismaClient();
const lambda = new LambdaClient({ region: process.env.AWS_REGION });
const secretsManagerClient = new SecretsManagerClient({ region: process.env.AWS_REGION });

const corsHeaders = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'OPTIONS,POST'
};

const MAX_RETRIES = 5;
const RETRY_DELAY_BASE = 200; // milliseconds

async function verifyToken(token) {
    const params = {
        FunctionName: 'verifyToken',
        Payload: JSON.stringify({ authToken: token }),
    };

    const command = new InvokeCommand(params);
    const response = await lambda.send(command);

    const result = JSON.parse(new TextDecoder().decode(response.Payload));

    if (result.errorMessage) {
        throw new Error(result.errorMessage);
    }

    const payload = JSON.parse(result.body);

    return payload;
}

async function validateUser(userId, householdId) {
    const user = await prisma.user.findUnique({
        where: { uuid: userId },
    });

    if (!user) {
        return false;
    }

    const householdMembers = await prisma.householdMembers.findMany({
        where: { householdId },
        select: { memberUuid: true },
    });

    const memberUuids = householdMembers.map(member => member.memberUuid);
    return memberUuids.includes(userId);
}

function calculateFutureDates(startDate, endDate, frequency) {
    const dates = [];
    let currentDate = new Date(startDate);
    const end = endDate ? new Date(endDate) : null;

    const incrementMap = {
        once: () => currentDate,
        weekly: () => currentDate.setDate(currentDate.getDate() + 7),
        biweekly: () => currentDate.setDate(currentDate.getDate() + 14),
        monthly: () => currentDate.setMonth(currentDate.getMonth() + 1),
        bimonthly: () => currentDate.setMonth(currentDate.getMonth() + 2),
        quarterly: () => currentDate.setMonth(currentDate.getMonth() + 3),
        semiAnnually: () => currentDate.setMonth(currentDate.getMonth() + 6),
        annually: () => currentDate.setFullYear(currentDate.getFullYear() + 1),
        semiMonthly: () => {
            const nextMonth = new Date(currentDate);
            nextMonth.setMonth(nextMonth.getMonth() + 1);

            if (currentDate.getDate() === 1) {
                currentDate.setDate(15);
            } else if (currentDate.getDate() === 15) {
                currentDate.setDate(1);
                currentDate.setMonth(currentDate.getMonth() + 1);
            } else {
                currentDate.setDate(currentDate.getDate() <= 15 ? 15 : 1);
                if (currentDate.getDate() === 1) {
                    currentDate.setMonth(currentDate.getMonth() + 1);
                }
            }

            if (end && currentDate > end) return false;
            return true;
        },
    };

    while (!end || currentDate <= end) {
        dates.push(new Date(currentDate));
        if (frequency === 'semiMonthly' && !incrementMap[frequency]()) break;
        else incrementMap[frequency]();
        if (frequency === 'once') break;
    }

    return dates;
}

async function createNotification(ledgerEntry, userUuid) {
    const params = {
        FunctionName: 'addNotification',
        Payload: JSON.stringify({
            userUuid,
            billId: ledgerEntry.billId,
            title: `Upcoming bill: ${ledgerEntry.category}`,
            message: `Your bill ${ledgerEntry.description} is due on ${ledgerEntry.transactionDate.toDateString()}`,
            dueDate: ledgerEntry.transactionDate.toISOString()
        }),
    };

    const command = new InvokeCommand(params);
    
    for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
        try {
            await lambda.send(command);
            break;
        } catch (error) {
            if (error.name === 'TooManyRequestsException' && attempt < MAX_RETRIES - 1) {
                const delay = RETRY_DELAY_BASE * Math.pow(2, attempt);
                console.warn(`Rate limit exceeded, retrying in ${delay}ms...`);
                await new Promise(resolve => setTimeout(resolve, delay));
            } else {
                throw new Error(`Error creating notification: ${error.message}`);
            }
        }
    }
}

async function invokeCalculateRunningTotal(householdId, paymentSourceId) {
    const params = {
        FunctionName: 'calculateRunningTotal',
        Payload: JSON.stringify({ householdId, paymentSourceId }),
    };

    const command = new InvokeCommand(params);

    for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
        try {
            const response = await lambda.send(command);
            const payload = JSON.parse(new TextDecoder().decode(response.Payload));

            if (payload.statusCode !== 200) {
                throw new Error(`Error invoking calculateRunningTotal: ${payload.message || 'unknown error'}`);
            }

            return payload.message;
        } catch (error) {
            if (error.name === 'TooManyRequestsException' && attempt < MAX_RETRIES - 1) {
                const delay = RETRY_DELAY_BASE * Math.pow(2, attempt);
                console.warn(`Rate limit exceeded, retrying in ${delay}ms...`);
                await new Promise(resolve => setTimeout(resolve, delay));
            } else {
                throw new Error(`Error invoking calculateRunningTotal: ${error.message}`);
            }
        }
    }
}

async function storeCredentialsInSecretsManager(billId, username, password) {
    const secretName = `bill-credentials/${billId}`;
    const secretValue = JSON.stringify({ username, password });

    const command = new CreateSecretCommand({
        Name: secretName,
        SecretString: secretValue,
    });

    const response = await secretsManagerClient.send(command);
    return response.ARN;
}

exports.handler = async (event) => {
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers: corsHeaders,
        };
    }

    const { authToken, householdId, billData } = JSON.parse(event.body);

    const requiredFields = ['category', 'billName', 'amount', 'startDate', 'frequency', 'description'];
    for (const field of requiredFields) {
        if (!billData[field]) {
            return {
                statusCode: 400,
                headers: corsHeaders,
                body: JSON.stringify({ message: `Missing required field: ${field}` }),
            };
        }
    }

    if (billData.frequency !== 'once' && !billData.endDate) {
        return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ message: 'Missing required field: endDate for the selected frequency' }),
        };
    }

    try {
        const payload = await verifyToken(authToken);
        if (!payload.user_id) {
            return {
                statusCode: 401,
                headers: corsHeaders,
                body: JSON.stringify({ message: 'Invalid authorization token' }),
            };
        }

        const userUuid = payload.user_id;

        const isValidUser = await validateUser(userUuid, householdId);
        if (!isValidUser) {
            return {
                statusCode: 401,
                headers: corsHeaders,
                body: JSON.stringify({ message: 'Invalid user or household association' }),
            };
        }

        if (billData.paymentSourceId) {
            const paymentSource = await prisma.paymentSource.findUnique({
                where: {
                    sourceId: billData.paymentSourceId,
                    householdId,
                },
            });

            if (!paymentSource) {
                return {
                    statusCode: 400,
                    headers: corsHeaders,
                    body: JSON.stringify({ message: 'Invalid paymentSourceId' }),
                };
            }
        }

        let parsedStartDate = format(fromUnixTime(billData.startDate / 1000), 'yyyy-MM-dd HH:mm:ss.SSS');
        let parsedEndDate = billData.frequency !== 'once' ? format(fromUnixTime(billData.endDate / 1000), 'yyyy-MM-dd HH:mm:ss.SSS') : null;

        const newBill = await prisma.bill.create({
            data: {
                householdId,
                category: billData.category,
                billName: billData.billName,
                amount: billData.amount,
                startDate: new Date(parsedStartDate),
                endDate: parsedEndDate ? new Date(parsedEndDate) : null,
                frequency: billData.frequency,
                description: billData.description,
                status: false,
                url: billData.url,
                createdAt: new Date(),
                updatedAt: new Date(),
            }
        });

        if (billData.username && billData.password) {
            const credentialsArn = await storeCredentialsInSecretsManager(newBill.billId, billData.username, billData.password);
            await prisma.bill.update({
                where: { billId: newBill.billId },
                data: {
                    username: credentialsArn,
                    password: credentialsArn,
                },
            });
        }

        const futureDates = calculateFutureDates(new Date(parsedStartDate), parsedEndDate ? new Date(parsedEndDate) : null, billData.frequency);

        const tags = `${billData.billName},${billData.category}`;

        const ledgerEntries = futureDates.map(date => ({
            householdId,
            paymentSourceId: billData.paymentSourceId,
            amount: billData.amount,
            transactionType: 'Debit',
            transactionDate: date,
            category: billData.category,
            description: `${billData.billName} | ${billData.description}`,
            status: false,
            createdAt: new Date(),
            updatedAt: new Date(),
            billId: newBill.billId,
            isInitial: false,
            runningTotal: 0.0,
            tags,
        }));

        await prisma.ledger.createMany({ data: ledgerEntries });

        await Promise.all(ledgerEntries.map(entry => createNotification(entry, userUuid)));

        await invokeCalculateRunningTotal(householdId, billData.paymentSourceId);

        return {
            statusCode: 201,
            headers: corsHeaders,
            body: JSON.stringify({ 
                message: 'Bill and ledger entries created successfully.',
                bill: newBill
            }),
        };
    } catch (error) {
        console.error('Error adding bill:', error);
        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({ message: 'Internal server error', error: error.message }),
        };
    } finally {
        await prisma.$disconnect();
    }
};
