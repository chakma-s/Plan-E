#!/usr/bin/env bash
# ============================================================================
# Plan-E Travel Reservation Ecosystem: One-Click Deployment & Bootstrap Script
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}===================================================================${NC}"
echo -e "${GREEN}      PLAN-E TRAVEL RESERVATION ECOSYSTEM: DEPLOYMENT SUITE       ${NC}"
echo -e "${BLUE}===================================================================${NC}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# 1. Environment Verification
if [ ! -f .env ]; then
    echo -e "${YELLOW}[!] .env not found. Creating from .env.example...${NC}"
    cp .env.example .env
fi

echo -e "${GREEN}[✓] Environment configuration verified.${NC}"

# 2. Run Test Suite Verification
echo -e "${BLUE}[*] Running Automated Verification Tests...${NC}"
python3 -m pytest backend/tests -v
echo -e "${GREEN}[✓] All automated domain tests passed successfully!${NC}"

# 3. Docker Compose Orchestration Check
if command -v docker &> /dev/null && command -v docker compose &> /dev/null; then
    echo -e "${BLUE}[*] Docker & Docker Compose detected.${NC}"
    echo -e "${BLUE}[*] Launching containerized ecosystem stack...${NC}"
    
    docker compose up -d --build

    echo -e "${GREEN}[✓] Containers launched. Awaiting database & API healthchecks...${NC}"
    
    # Wait for API healthcheck
    MAX_RETRIES=15
    COUNT=0
    until curl -s http://localhost:8000/health | grep -q "healthy" || [ $COUNT -eq $MAX_RETRIES ]; do
        sleep 2
        COUNT=$((COUNT + 1))
        echo -e "${YELLOW}    Waiting for FastAPI backend engine ($COUNT/$MAX_RETRIES)...${NC}"
    done

    if [ $COUNT -lt $MAX_RETRIES ]; then
        echo -e "${GREEN}[✓] Plan-E Ecosystem is LIVE and healthy!${NC}"
    else
        echo -e "${YELLOW}[!] Note: Containers are spinning up. Please check 'docker compose logs -f' if needed.${NC}"
    fi
else
    echo -e "${YELLOW}[!] Docker not running or unavailable. You can run locally using:${NC}"
    echo -e "    cd backend && uvicorn app.main:app --reload --port 8000"
fi

echo -e ""
echo -e "${GREEN}===================================================================${NC}"
echo -e "${GREEN}             ACCESS URLS & SERVICE DIRECTORY                       ${NC}"
echo -e "${GREEN}===================================================================${NC}"
echo -e " 🚀 FastAPI Backend API:          http://localhost:8000"
echo -e " 📖 OpenAPI / Swagger Docs:       http://localhost:8000/api/v1/docs"
echo -e " 🏨 Vendor Management Portal:     http://localhost/vendor (or open web_portal/vendor/index.html)"
echo -e " 🛡️ Admin Operations Dashboard:   http://localhost/admin  (or open web_portal/admin/index.html)"
echo -e " 📱 Flutter Mobile App:           cd mobile_app && flutter run"
echo -e "${GREEN}===================================================================${NC}"
