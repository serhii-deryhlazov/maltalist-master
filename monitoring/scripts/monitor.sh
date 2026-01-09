#!/bin/bash

timestamp=$(date +%s)

# Create stats directory if it doesn't exist
mkdir -p /var/www/html/stats

# Get stats as json array
stats=$(docker stats --no-stream --format '{"name":"{{.Name}}","cpu":"{{.CPUPerc}}","mem_perc":"{{.MemPerc}}","mem_usage":"{{.MemUsage}}"}' | jq -s .)

# Create entry
entry=$(jq -n --argjson ts $timestamp --argjson stats "$stats" '{timestamp: $ts, stats: $stats}')

# Initialize file if not exists
if [ ! -f /var/www/html/stats/stats.json ]; then
  echo '[]' > /var/www/html/stats/stats.json
fi

# Append to array and limit to 200 entries (remove oldest if > 200)
tmp=$(jq ". + [$entry] | if length > 200 then .[1:] else . end" /var/www/html/stats/stats.json)
echo "$tmp" > /var/www/html/stats/stats.json
