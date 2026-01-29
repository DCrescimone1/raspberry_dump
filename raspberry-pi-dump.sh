#!/bin/bash

################################################################################
# Raspberry Pi System Dump Script
# Outputs: Single comprehensive markdown file with all system info
################################################################################

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Output file
OUTPUT_FILE="$SCRIPT_DIR/raspberry-pi-dump.md"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Raspberry Pi System Dump${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${YELLOW}Collecting system information...${NC}"
echo -e "Output: ${YELLOW}$OUTPUT_FILE${NC}"
echo ""

# Start the markdown file
cat > "$OUTPUT_FILE" << 'HEADER_EOF'
# Raspberry Pi System Dump

**Generated:** TIMESTAMP_PLACEHOLDER
**Hostname:** HOSTNAME_PLACEHOLDER

---

HEADER_EOF

# Replace placeholders
sed -i "s/TIMESTAMP_PLACEHOLDER/$(date)/" "$OUTPUT_FILE"
sed -i "s/HOSTNAME_PLACEHOLDER/$(hostname)/" "$OUTPUT_FILE"

################################################################################
# TABLE OF CONTENTS
################################################################################
cat >> "$OUTPUT_FILE" << 'TOC_EOF'
## Table of Contents

1. [DNS Diagnostics](#dns-diagnostics)
2. [No-IP DDNS Status](#no-ip-ddns-status)
3. [PM2 Processes](#pm2-processes)
4. [Nginx Configuration](#nginx-configuration)
5. [System Services](#system-services)
6. [Scheduled Tasks (Cron)](#scheduled-tasks-cron)
7. [Network Information](#network-information)
8. [Firewall Rules](#firewall-rules)
9. [Project Ecosystem Files](#project-ecosystem-files)
10. [System Monitoring](#system-monitoring)
11. [Troubleshooting Recommendations](#troubleshooting-recommendations)

---

TOC_EOF

################################################################################
# 1. DNS DIAGNOSTICS
################################################################################
echo -e "${YELLOW}Running DNS diagnostics...${NC}"

cat >> "$OUTPUT_FILE" << 'DNS_HEADER_EOF'
## DNS Diagnostics

### Current IP Addresses

DNS_HEADER_EOF

# Public IP
PUBLIC_IP=$(curl -s ifconfig.me)
echo "**Public IP:** $PUBLIC_IP" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Local IP
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "**Local IP:** $LOCAL_IP" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Domain list
DOMAINS=(
    "www.marzagem.com"
    "marzagem.com"
    "www.acquamarina.net"
    "acquamarina.net"
    "memoria.acquamarina.net"
    "www.mynewsly.com"
    "mynewsly.com"
    "dubsy.ddns.net"
)

echo "### Domain DNS Resolution Status" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for domain in "${DOMAINS[@]}"; do
    resolved_ip=$(dig +short "$domain" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
    
    echo "#### $domain" >> "$OUTPUT_FILE"
    if [ -z "$resolved_ip" ]; then
        echo "- ❌ **SERVFAIL** - No DNS records found" >> "$OUTPUT_FILE"
    else
        if [ "$resolved_ip" = "$PUBLIC_IP" ]; then
            echo "- ✅ Resolves to: **$resolved_ip** (correct - matches public IP)" >> "$OUTPUT_FILE"
        else
            echo "- ⚠️  Resolves to: **$resolved_ip** (WARNING: does NOT match public IP $PUBLIC_IP)" >> "$OUTPUT_FILE"
        fi
    fi
    echo "" >> "$OUTPUT_FILE"
done

# Full dig output
echo "### Detailed DNS Queries (dig output)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for domain in "${DOMAINS[@]}"; do
    echo "<details>" >> "$OUTPUT_FILE"
    echo "<summary>📋 $domain - Full dig output</summary>" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    dig "$domain" 2>&1 >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "</details>" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

################################################################################
# 2. NO-IP DDNS STATUS
################################################################################
echo -e "${YELLOW}Collecting No-IP DDNS information...${NC}"

cat >> "$OUTPUT_FILE" << 'NOIP_HEADER_EOF'
## No-IP DDNS Status

### Current Status

```
NOIP_HEADER_EOF

sudo noip2 -S 2>&1 >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Service Status" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
systemctl status noip2 --no-pager 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Recent No-IP Logs (Last 200 entries)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "<details>" >> "$OUTPUT_FILE"
echo "<summary>📋 View Full Logs</summary>" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
sudo journalctl -u noip2 -n 200 --no-pager 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "</details>" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### No-IP Errors Only" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
sudo journalctl -u noip2 --no-pager 2>&1 | grep -i "error\|fail\|can't\|unable" | tail -50 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### IP Change History" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
sudo journalctl -u noip2 --no-pager 2>&1 | grep "set to" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

################################################################################
# 3. PM2 PROCESSES
################################################################################
echo -e "${YELLOW}Collecting PM2 process information...${NC}"

cat >> "$OUTPUT_FILE" << 'PM2_HEADER_EOF'
## PM2 Processes

### Process List

```
PM2_HEADER_EOF

pm2 list 2>&1 >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Detailed Process Information (JSON)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "<details>" >> "$OUTPUT_FILE"
echo "<summary>📋 View JSON Details</summary>" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```json' >> "$OUTPUT_FILE"
pm2 jlist 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "</details>" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

################################################################################
# 4. NGINX CONFIGURATION
################################################################################
echo -e "${YELLOW}Collecting nginx configurations...${NC}"

cat >> "$OUTPUT_FILE" << 'NGINX_HEADER_EOF'
## Nginx Configuration

### Nginx Status

```
NGINX_HEADER_EOF

sudo systemctl status nginx --no-pager 2>&1 >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Nginx Configuration Test" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
sudo nginx -t 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Enabled Sites" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for site in /etc/nginx/sites-enabled/*; do
    if [ -f "$site" ]; then
        sitename=$(basename "$site")
        echo "<details>" >> "$OUTPUT_FILE"
        echo "<summary>📄 $sitename</summary>" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo '```nginx' >> "$OUTPUT_FILE"
        sudo cat "$site" 2>&1 >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "</details>" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

################################################################################
# 5. SYSTEM SERVICES
################################################################################
echo -e "${YELLOW}Collecting system services...${NC}"

cat >> "$OUTPUT_FILE" << 'SERVICES_HEADER_EOF'
## System Services

### Failed Services

```
SERVICES_HEADER_EOF

systemctl list-units --state=failed --no-pager 2>&1 >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### All Services" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "<details>" >> "$OUTPUT_FILE"
echo "<summary>📋 View All Services</summary>" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
systemctl list-units --all --no-pager 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "</details>" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

################################################################################
# 6. SCHEDULED TASKS
################################################################################
echo -e "${YELLOW}Collecting scheduled tasks...${NC}"

cat >> "$OUTPUT_FILE" << 'CRON_HEADER_EOF'
## Scheduled Tasks (Cron)

### User Crontab

```
CRON_HEADER_EOF

crontab -l 2>&1 >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### System Crontab" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
sudo cat /etc/crontab 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Cron.d Directory" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
sudo ls -la /etc/cron.d/ 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Systemd Timers" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
systemctl list-timers --all --no-pager 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

################################################################################
# 7. NETWORK INFORMATION
################################################################################
echo -e "${YELLOW}Collecting network information...${NC}"

cat >> "$OUTPUT_FILE" << 'NETWORK_HEADER_EOF'
## Network Information

### /etc/hosts

```
NETWORK_HEADER_EOF

sudo cat /etc/hosts 2>&1 >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### /etc/resolv.conf" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
cat /etc/resolv.conf 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Network Interfaces" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
ip addr show 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Routing Table" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
ip route show 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Listening Ports" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
sudo netstat -tulpn 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Localhost Connection Test" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
curl -I localhost 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

################################################################################
# 8. FIREWALL RULES
################################################################################
echo -e "${YELLOW}Collecting firewall rules...${NC}"

cat >> "$OUTPUT_FILE" << 'FIREWALL_HEADER_EOF'
## Firewall Rules

### UFW Status

```
FIREWALL_HEADER_EOF

sudo ufw status verbose 2>&1 >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### IPTables Rules" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "<details>" >> "$OUTPUT_FILE"
echo "<summary>📋 View Full IPTables Rules</summary>" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
sudo iptables -L -n -v 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "</details>" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

################################################################################
# 9. PROJECT ECOSYSTEM FILES
################################################################################
echo -e "${YELLOW}Collecting project ecosystem files...${NC}"

cat >> "$OUTPUT_FILE" << 'PROJECTS_HEADER_EOF'
## Project Ecosystem Files

PROJECTS_HEADER_EOF

PROJECTS=(
    "acquamarina_website3"
    "memoria_landing"
    "mynewsly_webpage"
    "marzapage"
)

for project in "${PROJECTS[@]}"; do
    ecosystem_js="$HOME/projects/$project/ecosystem.config.js"
    ecosystem_cjs="$HOME/projects/$project/ecosystem.config.cjs"
    
    if [ -f "$ecosystem_js" ]; then
        echo "### $project (ecosystem.config.js)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo '```javascript' >> "$OUTPUT_FILE"
        cat "$ecosystem_js" 2>&1 >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "✓ Copied: $project/ecosystem.config.js"
    elif [ -f "$ecosystem_cjs" ]; then
        echo "### $project (ecosystem.config.cjs)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo '```javascript' >> "$OUTPUT_FILE"
        cat "$ecosystem_cjs" 2>&1 >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "✓ Copied: $project/ecosystem.config.cjs"
    else
        echo "### $project" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "⚠️ **NOT FOUND** - No ecosystem.config.js or ecosystem.config.cjs found" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "⚠ Missing: $project/ecosystem.config.{js,cjs}"
    fi
done

echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

################################################################################
# 10. SYSTEM MONITORING
################################################################################
echo -e "${YELLOW}Collecting monitoring data...${NC}"

cat >> "$OUTPUT_FILE" << 'MONITOR_HEADER_EOF'
## System Monitoring

### System Uptime

```
MONITOR_HEADER_EOF

uptime 2>&1 >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Recent Reboots" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
last reboot -10 2>&1 >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Network-Related System Logs (Last 500 lines)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "<details>" >> "$OUTPUT_FILE"
echo "<summary>📋 View Network Logs</summary>" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
sudo journalctl -n 500 --no-pager 2>&1 | grep -i "network\|dns\|connection" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "</details>" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

################################################################################
# 11. TROUBLESHOOTING RECOMMENDATIONS
################################################################################

cat >> "$OUTPUT_FILE" << 'TROUBLESHOOTING_EOF'
## Troubleshooting Recommendations

### DNS Issue Analysis

Based on the collected data:

1. **Check Domain DNS Records**
   - Verify that ALL domains point to the correct public IP or CNAME to `dubsy.ddns.net`
   - Ensure `www.` subdomains have proper DNS records (currently showing SERVFAIL)
   - Check DNS TTL settings (lower TTL = faster propagation but more queries)

2. **No-IP DDNS Monitoring**
   - Review error logs for patterns (network failures, update failures)
   - Current update interval: 30 minutes
   - Consider reducing to 5-10 minutes if IP changes frequently
   - Monitor "Can't gethostbyname" errors (indicates network connectivity issues)

3. **Nginx Configuration**
   - Verify server_name directives match domain names
   - Check for proper redirects (HTTP → HTTPS, non-www → www)
   - Ensure all sites are properly enabled

4. **Network Connectivity**
   - Monitor for public IP changes
   - Check ISP stability
   - Verify router port forwarding (80, 443, 2600)

### Common Issues

**Intermittent DNS Failures (3-4 times per week):**
- Possible causes:
  1. Public IP changes before No-IP updates
  2. No-IP service connectivity issues
  3. DNS TTL expiration during update window
  4. ISP temporary network issues

**Recommended Actions:**
1. Set up continuous monitoring to log failures
2. Reduce No-IP update frequency to 5-10 minutes
3. Consider using DNS health monitoring service
4. Keep logs of when failures occur to identify patterns

---

**End of Dump**
TROUBLESHOOTING_EOF

################################################################################
# COMPLETION
################################################################################
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Dump Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "Output file: ${YELLOW}$OUTPUT_FILE${NC}"
echo ""
FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
echo -e "File size: ${YELLOW}$FILE_SIZE${NC}"
echo ""
echo -e "${GREEN}You can now review the file or commit it to git.${NC}"
