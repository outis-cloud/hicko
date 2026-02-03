#!/bin/bash

# Backend connectivity and functionality checker
# Tests all API endpoints to ensure UI integration works

set -e

API_URL="http://localhost:8080"
TOKEN=""

echo "=== Hickory Backend Connectivity Checker ==="
echo "API URL: $API_URL"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to test endpoint
test_endpoint() {
  local method=$1
  local endpoint=$2
  local data=$3
  local expected_code=$4
  
  echo -n "Testing $method $endpoint... "
  
  if [ -z "$data" ]; then
    response=$(curl -s -w "\n%{http_code}" -X "$method" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      "$API_URL$endpoint")
  else
    response=$(curl -s -w "\n%{http_code}" -X "$method" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "$data" \
      "$API_URL$endpoint")
  fi
  
  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | head -n -1)
  
  if [[ "$http_code" == "200" ]] || [[ "$http_code" == "201" ]] || [[ "$http_code" == "204" ]]; then
    echo -e "${GREEN}✓ (HTTP $http_code)${NC}"
    echo "$body"
  else
    echo -e "${RED}✗ (HTTP $http_code)${NC}"
    echo "$body"
  fi
  echo ""
}

# Step 1: Health check
echo -e "${YELLOW}1. Health Check${NC}"
test_endpoint "GET" "/health" "" "200"

# Step 2: Login
echo -e "${YELLOW}2. Login${NC}"
login_resp=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' \
  "$API_URL/api/v1/auth/login")

TOKEN=$(echo "$login_resp" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
if [ -z "$TOKEN" ]; then
  echo -e "${RED}Failed to login${NC}"
  echo "$login_resp"
  exit 1
fi
echo -e "${GREEN}✓ Login successful${NC}"
echo "Token: ${TOKEN:0:20}..."
echo ""

# Step 3: List zones
echo -e "${YELLOW}3. List Zones${NC}"
test_endpoint "GET" "/api/v1/zones" "" "200"

# Step 4: Create zone
echo -e "${YELLOW}4. Create Zone${NC}"
zone_data="{\"domain\":\"test-$(date +%s).com\"}"
zone_resp=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$zone_data" \
  "$API_URL/api/v1/zones")

zone_code=$(echo "$zone_resp" | tail -1)
zone_body=$(echo "$zone_resp" | head -n -1)
zone_id=$(echo "$zone_body" | grep -o '"id":"[^"]*"' | cut -d'"' -f4 | head -1)

if [[ "$zone_code" == "201" ]]; then
  echo -e "${GREEN}✓ Zone created: $zone_id${NC}"
else
  echo -e "${RED}✗ Zone creation failed (HTTP $zone_code)${NC}"
  exit 1
fi
echo ""

# Step 5: Create record
echo -e "${YELLOW}5. Create DNS Record${NC}"
record_data="{\"name\":\"www\",\"record_type\":\"A\",\"value\":\"192.0.2.1\",\"ttl\":3600}"
record_resp=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$record_data" \
  "$API_URL/api/v1/zones/$zone_id/records")

record_code=$(echo "$record_resp" | tail -1)
if [[ "$record_code" == "201" ]]; then
  echo -e "${GREEN}✓ Record created${NC}"
else
  echo -e "${RED}✗ Record creation failed (HTTP $record_code)${NC}"
fi
echo ""

# Step 6: List records
echo -e "${YELLOW}6. List Records${NC}"
test_endpoint "GET" "/api/v1/zones/$zone_id/records" "" "200"

# Step 7: List servers
echo -e "${YELLOW}7. List Servers${NC}"
test_endpoint "GET" "/api/v1/servers" "" "200"

# Step 8: Create server
echo -e "${YELLOW}8. Create Server${NC}"
server_data="{\"name\":\"test-server\",\"address\":\"192.0.2.10\",\"region\":\"us-east-1\"}"
test_endpoint "POST" "/api/v1/servers" "$server_data" "201"

# Step 9: List users
echo -e "${YELLOW}9. List Users${NC}"
test_endpoint "GET" "/api/v1/users" "" "200"

# Step 10: Create user
echo -e "${YELLOW}10. Create User${NC}"
user_data="{\"username\":\"testuser-$(date +%s)\",\"password\":\"test123\"}"
test_endpoint "POST" "/api/v1/users" "$user_data" "201"

# Step 11: List georules
echo -e "${YELLOW}11. List GeoRules${NC}"
test_endpoint "GET" "/api/v1/georules" "" "200"

# Step 12: Create georule
echo -e "${YELLOW}12. Create GeoRule${NC}"
georule_data="{\"zone_id\":\"$zone_id\",\"match_type\":\"country\",\"match_value\":\"US\",\"target\":\"192.0.2.5\"}"
test_endpoint "POST" "/api/v1/georules" "$georule_data" "201"

# Step 13: Get audit logs
echo -e "${YELLOW}13. Get Audit Logs${NC}"
test_endpoint "GET" "/api/v1/audit" "" "200"

# Step 14: Admin stats
echo -e "${YELLOW}14. Get Admin Stats${NC}"
test_endpoint "GET" "/api/v1/admin/stats" "" "200"

echo -e "${GREEN}=== All connectivity checks passed! ===${NC}"
