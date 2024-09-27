// const { PrismaClient } = require('@prisma/client');
// const { Decimal } = require('decimal.js');

// const prisma = new PrismaClient();

// async function main() {
//   console.log('Start seeding ...');

//   // Create users
//   const user = await prisma.user.create({
//     data: {
//       firstName: 'John',
//       lastName: 'Doe',
//       email: 'john.doe@example.com',
//       signupDate: new Date(),
//       mailOptIn: true,
//       confirmedEmail: true,
//       createdAt: new Date(),
//       updatedAt: new Date()
//     },
//   });

//   const household = await prisma.household.create({
//     data: {
//       householdName: 'Doe Family',
//       creationDate: new Date(),
//       createdAt: new Date(),
//       updatedAt: new Date(),
//       setupComplete: true,
//       activeSubscription: true,
//     },
//   });

//   await prisma.householdMembers.create({
//     data: {
//       householdId: household.householdId,
//       memberUuid: user.uuid,
//       role: 'Owner',
//       joinedDate: new Date(),
//       createdAt: new Date(),
//       updatedAt: new Date(),
//     },
//   });

//   // Create payment source
//   const paymentSource = await prisma.paymentSource.create({
//     data: {
//       householdId: household.householdId,
//       sourceName: 'Bank Account',
//       sourceType: 'Checking',
//       description: 'Main household bank account',
//       createdAt: new Date(),
//       updatedAt: new Date(),
//     },
//   });

//   // Create bill
//   const bill = await prisma.bill.create({
//     data: {
//       householdId: household.householdId,
//       category: 'Utilities',
//       billName: 'Electricity Bill',
//       amount: new Decimal(100.00),
//       startDate: new Date('2024-07-01'),
//       endDate: new Date('2025-06-30'),
//       frequency: 'monthly',
//       description: 'Monthly electricity bill',
//       status: false,
//       url: 'https://utilitycompany.com/bill',
//       createdAt: new Date(),
//       updatedAt: new Date(),
//     },
//   });

//   // Create ledger entries
//   const startDate = new Date('2024-07-01');
//   const endDate = new Date('2025-06-30');
//   const futureDates = calculateFutureDates(startDate, endDate, 'monthly');

//   const ledgerEntries = futureDates.map(date => ({
//     householdId: household.householdId,
//     paymentSourceId: paymentSource.sourceId,
//     amount: new Decimal(100.00),
//     transactionType: 'Debit',
//     transactionDate: date,
//     category: 'Utilities',
//     description: 'Monthly electricity bill',
//     status: false,
//     createdAt: new Date(),
//     updatedAt: new Date(),
//     billId: bill.billId,
//     isInitial: false,
//     runningTotal: 0.0,
//     tags: 'Electricity,Utilities',
//   }));

//   await prisma.ledger.createMany({ data: ledgerEntries });

//   // Create income
//   const income = await prisma.incomes.create({
//     data: {
//       householdId: household.householdId,
//       name: 'Salary',
//       amount: new Decimal(5000.00),
//       frequency: 'monthly',
//       startDate: new Date('2024-07-01'),
//       endDate: new Date('2025-06-30'),
//       firstPayDay: new Date('2024-07-01'), // Ensure the firstPayDay is included
//       createdAt: new Date(),
//       updatedAt: new Date(),
//     },
//   });

//   console.log('Seeding finished.');
// }

// function calculateFutureDates(startDate, endDate, frequency) {
//   const dates = [];
//   let currentDate = new Date(startDate);

//   while (currentDate <= new Date(endDate)) {
//     dates.push(new Date(currentDate));

//     switch (frequency) {
//       case 'once':
//         return dates;
//       case 'weekly':
//         currentDate.setDate(currentDate.getDate() + 7);
//         break;
//       case 'biweekly':
//         currentDate.setDate(currentDate.getDate() + 14);
//         break;
//       case 'monthly':
//         currentDate.setMonth(currentDate.getMonth() + 1);
//         break;
//       case 'bimonthly':
//         currentDate.setMonth(currentDate.getMonth() + 2);
//         break;
//       case 'quarterly':
//         currentDate.setMonth(currentDate.getMonth() + 3);
//         break;
//       case 'semiAnnually':
//         currentDate.setMonth(currentDate.getMonth() + 6);
//         break;
//       case 'annually':
//         currentDate.setFullYear(currentDate.getFullYear() + 1);
//         break;
//       default:
//         throw new Error('Invalid frequency');
//     }
//   }
//   return dates;
// }

// main()
//   .catch((e) => {
//     console.error(e);
//     process.exit(1);
//   })
//   .finally(async () => {
//     await prisma.$disconnect();
//   });

