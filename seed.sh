#!/bin/bash

# Seed script for Maltalist API
# Usage: ./seed.sh <count>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <count>"
    echo "Example: $0 100"
    exit 1
fi

count=$1

# Validate that count is a positive integer
if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -le 0 ]; then
    echo "Error: Count must be a positive integer"
    exit 1
fi

echo "Seeding $count listings..."

# Make the POST request to the seed endpoint
response=$(curl -s -X POST "http://localhost:5023/api/Listings/seed/$count")

if [ $? -eq 0 ]; then
    echo "Seeding completed successfully:"
    echo "$response"
else
    echo "Error: Failed to seed listings"
    exit 1
fi
