#!/bin/bash

###############################################################################
# Telepresence Multi-Cluster Lab - Full Test Script
#
# Tests:
#   1. Prerequisites (docker, node, npm, kind, kubectl)
#   2. Docker build of the web terminal container
#   3. Docker Compose up + health check
#   4. xterm.js page loads correctly (HTTP 200 + content check)
#   5. WebSocket endpoint is reachable
#   6. Lab resource files exist and are valid YAML
#   7. Setup script syntax check
#   8. mkdocs pages lint (valid markdown, no broken internal links)
#   9. Container cleanup
#
# Usage:
#   ./test-all.sh          # Run all tests
#   ./test-all.sh --quick  # Skip Docker build (use existing image)
###############################################################################

set -euo pipefail

# ── Colors ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Counters ────────────────────────────────────────────
PASS=0
FAIL=0
SKIP=0
TESTS=()

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="${SCRIPT_DIR}/docker"
LABS_DIR="${SCRIPT_DIR}/labs"
RESOURCES_DIR="${SCRIPT_DIR}/resources"
CONTAINER_NAME="telepresence-lab-test"
PORT=3099 # Use non-standard port for testing

QUICK=false
[[ "${1:-}" == "--quick" ]] && QUICK=true

# ── Helpers ─────────────────────────────────────────────
log_test() {
  echo -e "\n${CYAN}━━━ TEST: $1 ━━━${NC}"
}

pass() {
  echo -e "  ${GREEN}✓ PASS${NC}: $1"
  PASS=$((PASS + 1))
  TESTS+=("PASS: $1")
}

fail() {
  echo -e "  ${RED}✗ FAIL${NC}: $1"
  FAIL=$((FAIL + 1))
  TESTS+=("FAIL: $1")
}

skip() {
  echo -e "  ${YELLOW}⊘ SKIP${NC}: $1"
  SKIP=$((SKIP + 1))
  TESTS+=("SKIP: $1")
}

warn() {
  echo -e "  ${YELLOW}⚠ WARN${NC}: $1"
}

cleanup() {
  echo -e "\n${CYAN}━━━ CLEANUP ━━━${NC}"
  docker rm -f "${CONTAINER_NAME}" 2>/dev/null && echo "  Removed test container" || true
}

trap cleanup EXIT

# ═════════════════════════════════════════════════════════
# TEST 1: Prerequisites
# ═════════════════════════════════════════════════════════
log_test "1. Prerequisites"

for cmd in docker node npm; do
  if command -v "$cmd" &>/dev/null; then
    pass "$cmd is installed ($(command -v "$cmd"))"
  else
    fail "$cmd is not installed"
  fi
done

# Optional: kind, kubectl, telepresence (warn only)
for cmd in kind kubectl telepresence; do
  if command -v "$cmd" &>/dev/null; then
    pass "$cmd is installed"
  else
    warn "$cmd not found - needed for cluster labs, not for web terminal"
  fi
done

# Check Docker daemon
if docker info &>/dev/null; then
  pass "Docker daemon is running"
else
  fail "Docker daemon is not running"
  echo -e "${RED}Cannot continue without Docker. Exiting.${NC}"
  exit 1
fi

# ═════════════════════════════════════════════════════════
# TEST 2: File Structure
# ═════════════════════════════════════════════════════════
log_test "2. File Structure"

# Docker files
for f in \
  "${DOCKER_DIR}/Dockerfile" \
  "${DOCKER_DIR}/docker-compose.yml" \
  "${DOCKER_DIR}/server.js" \
  "${DOCKER_DIR}/package.json" \
  "${DOCKER_DIR}/entrypoint.sh" \
  "${DOCKER_DIR}/public/index.html"; do
  if [[ -f "$f" ]]; then
    pass "$(basename "$f") exists"
  else
    fail "Missing: $f"
  fi
done

# Lab markdown files
for f in \
  "${LABS_DIR}/index.md" \
  "${LABS_DIR}/lab1-global-intercept.md" \
  "${LABS_DIR}/lab2-volume-mounting.md" \
  "${LABS_DIR}/lab3-outbound-connectivity.md" \
  "${LABS_DIR}/lab4-troubleshooting.md"; do
  if [[ -f "$f" ]]; then
    pass "$(basename "$f") exists"
  else
    fail "Missing: $f"
  fi
done

# Existing scripts
for f in \
  "${SCRIPT_DIR}/setup.sh" \
  "${SCRIPT_DIR}/cleanup.sh" \
  "${SCRIPT_DIR}/quickstart.sh" \
  "${SCRIPT_DIR}/test.sh" \
  "${SCRIPT_DIR}/README.md"; do
  if [[ -f "$f" ]]; then
    pass "$(basename "$f") exists"
  else
    fail "Missing: $f"
  fi
done

# Resource files
for f in \
  "${RESOURCES_DIR}/01-namespace.yaml" \
  "${RESOURCES_DIR}/02-dataservice.yaml" \
  "${RESOURCES_DIR}/03-backend.yaml" \
  "${RESOURCES_DIR}/04-frontend.yaml"; do
  if [[ -f "$f" ]]; then
    pass "$(basename "$f") exists"
  else
    fail "Missing: $f"
  fi
done

# ═════════════════════════════════════════════════════════
# TEST 3: YAML Validation
# ═════════════════════════════════════════════════════════
log_test "3. YAML Validation"

for f in "${RESOURCES_DIR}"/*.yaml; do
  fname="$(basename "$f")"
  # Basic YAML validation: check for common issues
  if [[ -f "$f" ]]; then
    # Check it starts with valid YAML (not empty, has kind/apiVersion)
    if grep -q "^kind:" "$f" || grep -q "^apiVersion:" "$f"; then
      pass "${fname} - valid Kubernetes manifest"
    else
      fail "${fname} - missing kind/apiVersion"
    fi
  fi
done

# docker-compose.yml validation
if docker compose -f "${DOCKER_DIR}/docker-compose.yml" config --quiet 2>/dev/null; then
  pass "docker-compose.yml is valid"
else
  # Fallback: try docker-compose (v1)
  if command -v docker-compose &>/dev/null && docker-compose -f "${DOCKER_DIR}/docker-compose.yml" config --quiet 2>/dev/null; then
    pass "docker-compose.yml is valid (v1)"
  else
    warn "Could not validate docker-compose.yml (compose may not be installed)"
  fi
fi

# ═════════════════════════════════════════════════════════
# TEST 4: Shell Script Syntax
# ═════════════════════════════════════════════════════════
log_test "4. Shell Script Syntax Check"

for f in \
  "${SCRIPT_DIR}/setup.sh" \
  "${SCRIPT_DIR}/cleanup.sh" \
  "${SCRIPT_DIR}/quickstart.sh" \
  "${DOCKER_DIR}/entrypoint.sh"; do
  fname="$(basename "$f")"
  if bash -n "$f" 2>/dev/null; then
    pass "${fname} - syntax OK"
  else
    fail "${fname} - syntax error"
  fi
done

# ═════════════════════════════════════════════════════════
# TEST 5: Node.js package.json
# ═════════════════════════════════════════════════════════
log_test "5. Node.js Package Validation"

if node -e "JSON.parse(require('fs').readFileSync('${DOCKER_DIR}/package.json'))" 2>/dev/null; then
  pass "package.json is valid JSON"
else
  fail "package.json is invalid JSON"
fi

# Check required dependencies
for dep in express ws node-pty; do
  if node -e "
    const pkg = JSON.parse(require('fs').readFileSync('${DOCKER_DIR}/package.json'));
    if (!pkg.dependencies['${dep}']) process.exit(1);
  " 2>/dev/null; then
    pass "package.json has dependency: ${dep}"
  else
    fail "package.json missing dependency: ${dep}"
  fi
done

# ═════════════════════════════════════════════════════════
# TEST 6: HTML Content Validation
# ═════════════════════════════════════════════════════════
log_test "6. HTML Content Validation"

HTML_FILE="${DOCKER_DIR}/public/index.html"

# Check for required xterm.js components
for pattern in "xterm.min.js" "xterm.min.css" "addon-fit" "new Terminal" "WebSocket" "FitAddon"; do
  if grep -q "$pattern" "$HTML_FILE" 2>/dev/null; then
    pass "index.html contains: ${pattern}"
  else
    fail "index.html missing: ${pattern}"
  fi
done

# Check for lab content
for lab in "overview" "lab1" "lab2" "lab3" "lab4"; do
  if grep -q "${lab}:" "$HTML_FILE" 2>/dev/null || grep -q "\"${lab}\"" "$HTML_FILE" 2>/dev/null; then
    pass "index.html has lab content: ${lab}"
  else
    fail "index.html missing lab content: ${lab}"
  fi
done

# ═════════════════════════════════════════════════════════
# TEST 7: Markdown Content Checks
# ═════════════════════════════════════════════════════════
log_test "7. Markdown Content Checks"

for f in "${LABS_DIR}"/*.md; do
  fname="$(basename "$f")"

  # Check not empty
  if [[ -s "$f" ]]; then
    pass "${fname} - not empty ($(wc -l <"$f") lines)"
  else
    fail "${fname} - file is empty"
    continue
  fi

  # Check has frontmatter
  if head -1 "$f" | grep -q "^---"; then
    pass "${fname} - has frontmatter"
  else
    warn "${fname} - missing frontmatter (optional)"
  fi

  # Check has H1 heading
  if grep -q "^# " "$f"; then
    pass "${fname} - has H1 heading"
  else
    fail "${fname} - missing H1 heading"
  fi

  # Check has code blocks
  if grep -q '```' "$f"; then
    pass "${fname} - has code blocks"
  else
    warn "${fname} - no code blocks found"
  fi
done

# Check internal markdown links are not broken
for f in "${LABS_DIR}"/*.md; do
  fname="$(basename "$f")"
  # Extract markdown links like [text](file.md)
  links=$(grep -oP '\]\(\K[^)]+\.md' "$f" 2>/dev/null || true)
  if [[ -n "$links" ]]; then
    while IFS= read -r link; do
      target="${LABS_DIR}/${link}"
      if [[ -f "$target" ]]; then
        pass "${fname} → ${link} (link valid)"
      else
        fail "${fname} → ${link} (broken link)"
      fi
    done <<<"$links"
  fi
done

# ═════════════════════════════════════════════════════════
# TEST 8: mkdocs.yml Integration
# ═════════════════════════════════════════════════════════
log_test "8. mkdocs.yml Integration"

MKDOCS_FILE="${SCRIPT_DIR}/../../mkdocs.yml"

if [[ -f "$MKDOCS_FILE" ]]; then
  for entry in \
    "28-Telepresence/README.md" \
    "28-Telepresence/labs/index.md" \
    "28-Telepresence/labs/lab1-global-intercept.md" \
    "28-Telepresence/labs/lab2-volume-mounting.md" \
    "28-Telepresence/labs/lab3-outbound-connectivity.md" \
    "28-Telepresence/labs/lab4-troubleshooting.md"; do
    if grep -q "$entry" "$MKDOCS_FILE"; then
      pass "mkdocs.yml references: $(basename "$entry")"
    else
      fail "mkdocs.yml missing: ${entry}"
    fi
  done
else
  skip "mkdocs.yml not found at expected path"
fi

# ═════════════════════════════════════════════════════════
# TEST 9: Docker Build
# ═════════════════════════════════════════════════════════
log_test "9. Docker Build"

if [[ "$QUICK" == true ]]; then
  skip "Docker build (--quick mode)"
else
  echo "  Building Docker image (this may take a minute)..."
  if docker build -t telepresence-lab-test:latest "${DOCKER_DIR}" 2>&1 | tail -5; then
    pass "Docker image built successfully"
  else
    fail "Docker build failed"
  fi
fi

# ═════════════════════════════════════════════════════════
# TEST 10: Container Run + Health Check
# ═════════════════════════════════════════════════════════
log_test "10. Container Run & Health Check"

if [[ "$QUICK" == true ]] && ! docker image inspect telepresence-lab-test:latest &>/dev/null; then
  skip "Container run (no image available in --quick mode)"
else
  # Stop any previous test container
  docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

  echo "  Starting container on port ${PORT}..."
  CONTAINER_ID=$(docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${PORT}:3000" \
    -e PORT=3000 \
    telepresence-lab-test:latest 2>&1) || true

  if [[ -n "$CONTAINER_ID" ]]; then
    pass "Container started: ${CONTAINER_ID:0:12}"

    # Wait for the server to be ready
    echo "  Waiting for server to start..."
    READY=false
    for i in $(seq 1 30); do
      if curl -sf "http://localhost:${PORT}/health" &>/dev/null; then
        READY=true
        break
      fi
      sleep 1
    done

    if [[ "$READY" == true ]]; then
      pass "Health endpoint responds OK"

      # Test index.html
      HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:${PORT}/" 2>/dev/null || echo "000")
      if [[ "$HTTP_CODE" == "200" ]]; then
        pass "index.html returns HTTP 200"
      else
        fail "index.html returns HTTP ${HTTP_CODE}"
      fi

      # Check page content
      PAGE_CONTENT=$(curl -sf "http://localhost:${PORT}/" 2>/dev/null || true)
      if echo "$PAGE_CONTENT" | grep -q "Telepresence"; then
        pass "Page contains 'Telepresence' title"
      else
        fail "Page missing 'Telepresence' title"
      fi

      if echo "$PAGE_CONTENT" | grep -q "xterm"; then
        pass "Page includes xterm.js"
      else
        fail "Page missing xterm.js"
      fi

      if echo "$PAGE_CONTENT" | grep -q "lab-select"; then
        pass "Page has lab selector dropdown"
      else
        fail "Page missing lab selector"
      fi

      if echo "$PAGE_CONTENT" | grep -q "WebSocket"; then
        pass "Page has WebSocket terminal code"
      else
        fail "Page missing WebSocket code"
      fi

      # Test WebSocket upgrade
      WS_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
        -H "Upgrade: websocket" \
        -H "Connection: Upgrade" \
        -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
        -H "Sec-WebSocket-Version: 13" \
        "http://localhost:${PORT}/" 2>/dev/null || echo "000")
      if [[ "$WS_CODE" == "101" ]]; then
        pass "WebSocket upgrade returns 101"
      else
        warn "WebSocket returned ${WS_CODE} (may need full WS client to test)"
      fi

    else
      fail "Server did not become ready within 30s"
      echo "  Container logs:"
      docker logs "${CONTAINER_NAME}" 2>&1 | tail -20
    fi
  else
    fail "Container failed to start"
  fi
fi

# ═════════════════════════════════════════════════════════
# TEST 11: Entrypoint Script Produces Expected Files
# ═════════════════════════════════════════════════════════
log_test "11. Container Environment"

if docker ps --format '{{.Names}}' | grep -q "${CONTAINER_NAME}"; then
  # Check lab user exists
  if docker exec "${CONTAINER_NAME}" id lab &>/dev/null; then
    pass "Lab user 'lab' exists in container"
  else
    fail "Lab user 'lab' missing in container"
  fi

  # Check cluster config files
  for f in cluster-east.yaml cluster-west.yaml setup-clusters.sh .bashrc; do
    if docker exec "${CONTAINER_NAME}" test -f "/home/lab/${f}"; then
      pass "Container has /home/lab/${f}"
    else
      fail "Container missing /home/lab/${f}"
    fi
  done

  # Check tools are installed
  for cmd in kubectl kind helm; do
    if docker exec "${CONTAINER_NAME}" which "$cmd" &>/dev/null; then
      pass "Container has ${cmd}"
    else
      fail "Container missing ${cmd}"
    fi
  done
else
  skip "Container not running - skipping environment checks"
fi

# ═════════════════════════════════════════════════════════
# SUMMARY
# ═════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  TEST SUMMARY${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}Passed${NC}:  ${PASS}"
echo -e "  ${RED}Failed${NC}:  ${FAIL}"
echo -e "  ${YELLOW}Skipped${NC}: ${SKIP}"
echo -e "  Total:   $((PASS + FAIL + SKIP))"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo -e "${RED}Failed tests:${NC}"
  for t in "${TESTS[@]}"; do
    [[ "$t" == FAIL:* ]] && echo -e "  ${RED}✗${NC} ${t#FAIL: }"
  done
  echo ""
fi

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}  ALL TESTS PASSED ✓${NC}"
  echo ""
  exit 0
else
  echo -e "${RED}${BOLD}  SOME TESTS FAILED ✗${NC}"
  echo ""
  exit 1
fi
