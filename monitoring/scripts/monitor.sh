#!/bin/bash

timestamp=$(date +%s)

# Get stats as json array
stats=$(docker stats --no-stream --format '{"name":"{{.Name}}","cpu":"{{.CPUPerc}}","mem_perc":"{{.MemPerc}}","mem_usage":"{{.MemUsage}}"}' | jq -s .)

# Create entry
entry=$(jq -n --argjson ts $timestamp --argjson stats "$stats" '{timestamp: $ts, stats: $stats}')

# Initialize file if not exists
if [ ! -f /var/www/html/stats.json ]; then
  echo '[]' > /var/www/html/stats.json
fi

# Append to array
tmp=$(jq ". + [$entry]" /var/www/html/stats.json)
echo "$tmp" > /var/www/html/stats.json
