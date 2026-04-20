#!/bin/bash

# ============================================
# LLM Forwarder - Key Management Script
# ============================================

# Configuration
PROXY_URL="${PROXY_URL:-http://localhost:4000}"
MASTER_KEY="${MASTER_KEY:-sk-admin-change-this-in-production}"
MODEL_ALIAS="${MODEL_ALIAS:-my-model}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}LLM Forwarder - Key Management${NC}"
echo "======================================"

# Function to generate a new API key
generate_key() {
    local key_name="$1"
    local duration="$2"
    local rate_limit="$3"
    local budget="$4"

    echo -e "${YELLOW}Creating API key: $key_name${NC}"

    response=$(curl -s -X POST "${PROXY_URL}/key/generate" \
        -H "Authorization: Bearer ${MASTER_KEY}" \
        -H "Content-Type: application/json" \
        -d "{
            \"key_alias\": \"${key_name}\",
            \"duration\": \"${duration}\",
            \"rpm\": ${rate_limit:-100},
            \"tpm\": ${budget:-100000},
            \"models\": [\"${MODEL_ALIAS}\"],
            \"metadata\": {
                \"project\": \"${key_name}\",
                \"created_by\": \"admin\"
            }
        }")

    if echo "$response" | grep -q "key"; then
        api_key=$(echo "$response" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
        echo -e "${GREEN}API Key created successfully!${NC}"
        echo "Key: $api_key"
        echo ""
        echo "Usage example:"
        echo "  curl ${PROXY_URL}/v1/chat/completions \\"
        echo "    -H \"Authorization: Bearer $api_key\" \\"
        echo "    -H \"Content-Type: application/json\" \\"
        echo "    -d '{\"model\": \"${MODEL_ALIAS}\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello\"}]}'"
    else
        echo -e "${RED}Failed to create key${NC}"
        echo "$response"
    fi
}

# Function to list all API keys
list_keys() {
    echo -e "${YELLOW}Listing all API keys...${NC}"
    curl -s "${PROXY_URL}/key/info" \
        -H "Authorization: Bearer ${MASTER_KEY}" | python3 -m json.tool 2>/dev/null || \
    curl -s "${PROXY_URL}/key/info" \
        -H "Authorization: Bearer ${MASTER_KEY}"
}

# Function to view usage stats
view_usage() {
    local key="$1"
    if [ -z "$key" ]; then
        echo -e "${YELLOW}Viewing global usage...${NC}"
        curl -s "${PROXY_URL}/spend/info" \
            -H "Authorization: Bearer ${MASTER_KEY}" | python3 -m json.tool 2>/dev/null || \
        curl -s "${PROXY_URL}/spend/info" \
            -H "Authorization: Bearer ${MASTER_KEY}"
    else
        echo -e "${YELLOW}Usage for key: $key${NC}"
        curl -s "${PROXY_URL}/key/info?key=$key" \
            -H "Authorization: Bearer ${MASTER_KEY}" | python3 -m json.tool 2>/dev/null || \
        curl -s "${PROXY_URL}/key/info?key=$key" \
            -H "Authorization: Bearer ${MASTER_KEY}"
    fi
}

# Function to delete an API key
delete_key() {
    local key="$1"
    echo -e "${YELLOW}Deleting API key: $key${NC}"
    curl -s -X DELETE "${PROXY_URL}/key/delete" \
        -H "Authorization: Bearer ${MASTER_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"key\": \"$key\"}"
    echo -e "${GREEN}Key deleted${NC}"
}

# Function to view available models
view_models() {
    echo -e "${YELLOW}Available models...${NC}"
    curl -s "${PROXY_URL}/v1/models" \
        -H "Authorization: Bearer ${MASTER_KEY}" | python3 -m json.tool 2>/dev/null || \
    curl -s "${PROXY_URL}/v1/models" \
        -H "Authorization: Bearer ${MASTER_KEY}"
}

# Main menu
case "${1:-help}" in
    generate)
        generate_key "${2:-my-project}" "${3:-30d}" "${4:-100}" "${5:-100000}"
        ;;
    list)
        list_keys
        ;;
    usage)
        view_usage "$2"
        ;;
    delete)
        delete_key "$2"
        ;;
    models)
        view_models
        ;;
    help|*)
        echo ""
        echo "Usage:"
        echo "  $0 generate <name> [duration] [rpm] [tpm]"
        echo "    Create a new API key"
        echo "    Example: $0 generate my-project 30d 100 100000"
        echo ""
        echo "  $0 list"
        echo "    List all API keys"
        echo ""
        echo "  $0 usage [key]"
        echo "    View usage statistics"
        echo ""
        echo "  $0 delete <key>"
        echo "    Delete an API key"
        echo ""
        echo "  $0 models"
        echo "    View available models"
        echo ""
        echo "Environment variables:"
        echo "  PROXY_URL      - Proxy URL (default: http://localhost:4000)"
        echo "  MASTER_KEY     - Admin master key"
        echo "  MODEL_ALIAS   - Model alias (default: my-model)"
        echo ""
        ;;
esac