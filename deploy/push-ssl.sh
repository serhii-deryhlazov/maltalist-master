#!/bin/bash

# Script to push SSL certificates to VPS
# Usage: ./push-ssl.sh

set -e

# Configuration
VPS_USER="root"
VPS_HOST="maltalisting.com"
LOCAL_SSL_DIR="./ssl/maltalisting.com"
REMOTE_SSL_DIR="/etc/ssl/maltalisting.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Pushing SSL certificates to VPS ===${NC}"
echo ""

# Check if local SSL directory exists
if [ ! -d "$LOCAL_SSL_DIR" ]; then
    echo -e "${RED}Error: Local SSL directory not found: $LOCAL_SSL_DIR${NC}"
    exit 1
fi

# Check if there are files to copy
if [ -z "$(ls -A $LOCAL_SSL_DIR)" ]; then
    echo -e "${RED}Error: No files found in $LOCAL_SSL_DIR${NC}"
    exit 1
fi

echo -e "${YELLOW}Local SSL files:${NC}"
ls -lh "$LOCAL_SSL_DIR"
echo ""

# Confirm before proceeding
read -p "Do you want to copy these SSL certificates to ${VPS_USER}@${VPS_HOST}:${REMOTE_SSL_DIR}? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

echo -e "${YELLOW}Creating remote directory if it doesn't exist...${NC}"
ssh ${VPS_USER}@${VPS_HOST} "mkdir -p ${REMOTE_SSL_DIR}"

echo -e "${YELLOW}Copying SSL certificates...${NC}"
scp -r ${LOCAL_SSL_DIR}/* ${VPS_USER}@${VPS_HOST}:${REMOTE_SSL_DIR}/

echo -e "${YELLOW}Setting proper permissions on VPS...${NC}"
ssh ${VPS_USER}@${VPS_HOST} "chmod 600 ${REMOTE_SSL_DIR}/*.key 2>/dev/null || true"
ssh ${VPS_USER}@${VPS_HOST} "chmod 644 ${REMOTE_SSL_DIR}/*.crt 2>/dev/null || true"
ssh ${VPS_USER}@${VPS_HOST} "chmod 644 ${REMOTE_SSL_DIR}/*.pem 2>/dev/null || true"

echo ""
echo -e "${GREEN}✓ SSL certificates successfully pushed to VPS${NC}"
echo ""
echo -e "${YELLOW}Verifying files on VPS:${NC}"
ssh ${VPS_USER}@${VPS_HOST} "ls -lh ${REMOTE_SSL_DIR}"

echo ""
read -p "Do you want to restart nginx now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Restarting nginx...${NC}"
    ssh ${VPS_USER}@${VPS_HOST} "systemctl restart nginx"
    echo -e "${GREEN}✓ Nginx restarted successfully${NC}"
else
    echo -e "${YELLOW}Skipped nginx restart. You can restart it manually later:${NC}"
    echo -e "${YELLOW}  ssh ${VPS_USER}@${VPS_HOST} 'systemctl restart nginx'${NC}"
fi
