#!/bin/bash

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================================"
echo "           Maltalist Full Test Suite Runner"
echo "======================================================================${NC}"
echo ""

# Track overall results
TOTAL_FAILED=0
TOTAL_PASSED=0

# Run Angular UI tests
echo -e "${BLUE}[1/2] Running Angular UI Tests...${NC}"
echo ""
cd maltalist-angular
if ./run-ui-tests.sh; then
    echo -e "${GREEN}[SUCCESS] Angular UI tests passed! ✅${NC}"
    echo ""
else
    echo -e "${RED}[ERROR] Angular UI tests failed! ❌${NC}"
    echo ""
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi
cd ..

# Run .NET API tests
echo -e "${BLUE}[2/2] Running .NET API Tests...${NC}"
echo ""
cd maltalist-api
if ./run-api-tests.sh; then
    echo -e "${GREEN}[SUCCESS] .NET API tests passed! ✅${NC}"
    echo ""
else
    echo -e "${RED}[ERROR] .NET API tests failed! ❌${NC}"
    echo ""
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi
cd ..

# Summary
echo -e "${BLUE}======================================================================"
echo "                         Test Summary"
echo "======================================================================${NC}"

if [ $TOTAL_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All test suites passed!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}❌ $TOTAL_FAILED test suite(s) failed!${NC}"
    echo ""
    exit 1
fi
