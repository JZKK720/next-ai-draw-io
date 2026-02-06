#!/bin/bash
# Ollama Docker Setup Verification Script
# Run this to check if your Ollama + Docker configuration is correct

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Ollama Docker Setup Verification${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check 1: Ollama running on host
echo -e "${CYAN}[1/6] Checking Ollama on host...${NC}"
OLLAMA_HOST=""
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    OLLAMA_HOST=$(curl -s http://localhost:11434/api/tags)
    echo -e "${GREEN}  ✓ Ollama is running on localhost:11434${NC}"
    echo -e "${GREEN}  Found models:${NC}"
    echo "$OLLAMA_HOST" | grep -o '"name":"[^"]*"' | sed 's/"name":"/  - /' | sed 's/"//'
else
    echo -e "${RED}  ✗ Cannot connect to Ollama on localhost:11434${NC}"
    echo -e "${YELLOW}  Make sure Ollama is running: 'ollama serve'${NC}"
fi
echo ""

# Check 2: Docker running
echo -e "${CYAN}[2/6] Checking Docker...${NC}"
if docker info > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Docker is running${NC}"
else
    echo -e "${RED}  ✗ Docker is not running${NC}"
    exit 1
fi
echo ""

# Check 3: Configuration files exist
echo -e "${CYAN}[3/6] Checking configuration files...${NC}"
files=(".env" "ai-models.json" "docker-compose.yml")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}  ✓ $file exists${NC}"
    else
        echo -e "${RED}  ✗ $file missing (REQUIRED)${NC}"
    fi
done
echo ""

# Check 4: Environment variables
echo -e "${CYAN}[4/6] Checking .env configuration...${NC}"
if [ -f ".env" ]; then
    grep -q "AI_PROVIDER=ollama" .env && echo -e "${GREEN}  ✓ AI provider set to Ollama${NC}" || echo -e "${RED}  ✗ AI provider not set to Ollama${NC}"
    grep -q "ALLOW_PRIVATE_URLS=true" .env && echo -e "${GREEN}  ✓ Private URLs allowed${NC}" || echo -e "${RED}  ✗ ALLOW_PRIVATE_URLS not set to true${NC}"
    grep -q "OLLAMA_BASE_URL" .env && echo -e "${GREEN}  ✓ Ollama base URL configured${NC}" || echo -e "${RED}  ✗ OLLAMA_BASE_URL not set${NC}"
    grep -q "AI_MODELS_CONFIG_PATH" .env && echo -e "${GREEN}  ✓ Multi-model config path set${NC}" || echo -e "${RED}  ✗ AI_MODELS_CONFIG_PATH not set${NC}"
fi
echo ""

# Check 5: Docker containers
echo -e "${CYAN}[5/6] Checking Docker containers...${NC}"
if docker-compose ps > /dev/null 2>&1; then
    echo -e "${GREEN}  Docker Compose services:${NC}"
    docker-compose ps
    
    if docker-compose ps | grep -q "next-ai-draw-io.*Up"; then
        echo -e "${GREEN}  ✓ next-ai-draw-io container is running${NC}"
    else
        echo -e "${RED}  ✗ next-ai-draw-io container is not running${NC}"
        echo -e "${YELLOW}  Run: docker-compose up -d${NC}"
    fi
else
    echo -e "${YELLOW}  ! No containers running. Start with: docker-compose up -d${NC}"
fi
echo ""

# Check 6: Test Ollama from inside container
echo -e "${CYAN}[6/6] Testing Ollama from inside container...${NC}"
if [ -n "$OLLAMA_HOST" ]; then
    if docker-compose exec -T next-ai-draw-io sh -c "curl -s http://host.docker.internal:11434/api/tags" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ Container can reach Ollama at host.docker.internal:11434${NC}"
    else
        echo -e "${RED}  ✗ Container cannot reach Ollama via host.docker.internal${NC}"
        echo -e "${YELLOW}  Trying alternative: Docker bridge IP...${NC}"
        
        # Try to find Docker bridge IP
        DOCKER_IP=$(ip addr show docker0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
        if [ -z "$DOCKER_IP" ]; then
            DOCKER_IP="172.17.0.1"  # Default Docker bridge
        fi
        
        if docker-compose exec -T next-ai-draw-io sh -c "curl -s http://$DOCKER_IP:11434/api/tags" > /dev/null 2>&1; then
            echo -e "${GREEN}  ✓ Found Ollama at $DOCKER_IP:11434${NC}"
            echo -e "${YELLOW}  Update OLLAMA_BASE_URL to: http://$DOCKER_IP:11434${NC}"
        else
            echo -e "${RED}  ✗ Cannot reach Ollama from container${NC}"
        fi
    fi
else
    echo -e "${YELLOW}  ! Skipping (Ollama not running on host)${NC}"
fi
echo ""

# Summary
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Summary & Next Steps${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

if [ -n "$OLLAMA_HOST" ]; then
    echo -e "${GREEN}✓ Ollama is ready on your host machine${NC}"
    echo ""
    echo -e "${CYAN}To start the application:${NC}"
    echo -e "  ${WHITE}1. docker-compose up -d${NC}"
    echo -e "  ${WHITE}2. Open http://localhost:3201${NC}"
    echo -e "  ${WHITE}3. Click Settings → API Keys & Models${NC}"
    echo -e "  ${WHITE}4. Select your Ollama model${NC}"
else
    echo -e "${RED}✗ Please start Ollama first:${NC}"
    echo -e "  ${WHITE}ollama serve${NC}"
    echo ""
    echo -e "${YELLOW}Then pull a model:${NC}"
    echo -e "  ${WHITE}ollama pull llama3.2${NC}"
fi
echo ""
echo -e "${CYAN}For troubleshooting, see: docs/en/ollama-docker-setup.md${NC}"
