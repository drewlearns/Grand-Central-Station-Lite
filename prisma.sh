#!/bin/bash
npx prisma migrate dev --name init
npx prisma db seed
