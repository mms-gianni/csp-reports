#!/bin/bash

# CSP Report Test Script
# This script sends sample CSP violation reports to test your logging stack

# Configuration
ENDPOINT="http://localhost:514"  # Vector syslog endpoint
REPORTS_ENDPOINT="http://localhost:8080"  # Alternative HTTP endpoint

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}CSP Report Test Script${NC}"
echo "========================="

# Function to send CSP report
send_csp_report() {
    local report_type="$1"
    local report_data="$2"
    
    # Compress JSON to single line by removing newlines and extra spaces
    local compressed_data=$(echo "$report_data" | tr -d '\n\r' | sed 's/[[:space:]]\+/ /g' | sed 's/{ /{/g' | sed 's/ }/}/g' | sed 's/\[ /[/g' | sed 's/ \]/]/g' | sed 's/, /,/g' | sed 's/: /:/g')
    
    echo -e "\n${YELLOW}Sending $report_type CSP report...${NC}"
    
    # Also try sending to alternative endpoint if available
    if curl -s --head "$REPORTS_ENDPOINT" > /dev/null 2>&1; then
        echo "Sending to alternative endpoint..."
        curl -X POST \
            -H "Content-Type: application/json" \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -d "$compressed_data" \
            "$REPORTS_ENDPOINT" \
            --silent \
            --write-out "HTTP Status: %{http_code}\n"
    fi
}

DEBUG='{"debug": true,"message": "CSP report test script running","timestamp": "$(date +%Y-%m-%dT%H:%M:%S%z)"}'
DD='{"key": "val", "timestamp": "$(date +%Y-%m-%dT%H:%M:%S%z)"}'
DD='{"age":12345,"body":{"blockedURL":"inline","columnNumber":15,"disposition":"enforce","documentURL":"https://example.com/page","effectiveDirective":"script-src-elem","lineNumber":42,"originalPolicy":"default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; report-to csp-endpoint","referrer":"https://www.google.com/","sample":"console.log(\"blocked script\")","sourceFile":"https://example.com/page","statusCode":200},"type":"csp-violation","url":"https://example.com/page","user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36"}'

# Sample CSP violation report - Script source violation
SCRIPT_VIOLATION='{
  "age": 12345,
  "body": {
    "blockedURL": "inline",
    "columnNumber": 15,
    "disposition": "enforce",
    "documentURL": "https://example.com/page",
    "effectiveDirective": "script-src-elem",
    "lineNumber": 42,
    "originalPolicy": "default-src '\''self'\''; script-src '\''self'\'' '\''unsafe-inline'\'' '\''unsafe-eval'\''; report-to csp-endpoint",
    "referrer": "https://www.google.com/",
    "sample": "console.log(\"blocked script\")",
    "sourceFile": "https://example.com/page",
    "statusCode": 200
  },
  "type": "csp-violation",
  "url": "https://example.com/page",
  "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36"
}'

# Sample CSP violation report - Style source violation
STYLE_VIOLATION='{
  "age": 5432,
  "body": {
    "blockedURL": "https://malicious-cdn.com/evil.css",
    "columnNumber": 1,
    "disposition": "enforce",
    "documentURL": "https://example.com/shop",
    "effectiveDirective": "style-src",
    "lineNumber": 1,
    "originalPolicy": "default-src '\''self'\''; style-src '\''self'\'' https://trusted-cdn.com; report-to csp-endpoint",
    "referrer": "",
    "sample": "",
    "sourceFile": "https://example.com/shop",
    "statusCode": 200
  },
  "type": "csp-violation",
  "url": "https://example.com/shop",
  "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36"
}'

# Sample CSP violation report - Image source violation
IMAGE_VIOLATION='{
  "age": 8765,
  "body": {
    "blockedURL": "https://untrusted-images.com/ad.png",
    "columnNumber": 0,
    "disposition": "enforce",
    "documentURL": "https://example.com/blog/post-123",
    "effectiveDirective": "img-src",
    "lineNumber": 0,
    "originalPolicy": "default-src '\''self'\''; img-src '\''self'\'' data: https://cdn.example.com; report-to csp-endpoint",
    "referrer": "https://example.com/blog",
    "sample": "",
    "sourceFile": "https://example.com/blog/post-123",
    "statusCode": 200
  },
  "type": "csp-violation",
  "url": "https://example.com/blog/post-123",
  "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36"
}'

# Send the reports
send_csp_report "Script Violation" "$DD"
#exit 0
#sleep 1

send_csp_report "Script Violation" "$SCRIPT_VIOLATION"
#sleep 1

send_csp_report "Style Violation" "$STYLE_VIOLATION"
#sleep 1

send_csp_report "Image Violation" "$IMAGE_VIOLATION"

echo -e "\n${GREEN}All CSP reports sent!${NC}"
echo -e "${YELLOW}Check your Grafana dashboard at http://localhost:3000 to view the reports${NC}"
echo -e "${YELLOW}Vector API available at http://localhost:8686${NC}"
