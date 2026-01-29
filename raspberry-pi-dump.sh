#!/bin/bash

################################################################################
# Raspberry Pi System Dump Script
# Collects complete system configuration for troubleshooting
# Focus: DNS issues, No-IP DDNS, nginx configs, PM2 processes
################################################################################

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Base dump directory (overwrites each time) - in same folder as script
DUMP_DIR="$SCRIPT_DIR/raspberry-pi-dump"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Raspberry Pi System Dump${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Create directory structure
echo -e "${YELLOW}Creating dump directory structure...${NC}"
rm -rf "$DUMP_DIR"
mkdir -p "$DUMP_DIR"/{system,nginx,dns-diagnostics,noip,projects,network,monitoring}

################################################################################
# SYSTEM INFORMATION
################################################################################
echo -e "${YELLOW}Collecting system information...${NC}"

# System services
systemctl list-units --all --no-pager > "$DUMP_DIR/system/systemd-services.txt"
systemctl list-units --state=failed --no-pager > "$DUMP_DIR/system/failed-services.txt"

# PM2 status
pm2 list 2>/dev/null > "$DUMP_DIR/system/pm2-list.txt"
pm2 jlist 2>/dev/null > "$DUMP_DIR/system/pm2-list.json"
pm2 prettylist 2>/dev/null > "$DUMP_DIR/system/pm2-detailed.txt"

# Cron jobs
echo "=== USER CRONTAB ===" > "$DUMP_DIR/system/cron-jobs.txt"
crontab -l 2>/dev/null >> "$DUMP_DIR/system/cron-jobs.txt" || echo "No user crontab" >> "$DUMP_DIR/system/cron-jobs.txt"
echo -e "\n=== SYSTEM CRONTAB ===" >> "$DUMP_DIR/system/cron-jobs.txt"
sudo cat /etc/crontab >> "$DUMP_DIR/system/cron-jobs.txt" 2>/dev/null
echo -e "\n=== CRON.D ===" >> "$DUMP_DIR/system/cron-jobs.txt"
sudo ls -la /etc/cron.d/ >> "$DUMP_DIR/system/cron-jobs.txt" 2>/dev/null

# Systemd timers
systemctl list-timers --all --no-pager > "$DUMP_DIR/system/systemd-timers.txt"

################################################################################
# NGINX CONFIGURATION
################################################################################
echo -e "${YELLOW}Collecting nginx configurations...${NC}"

# Copy all enabled sites
for site in /etc/nginx/sites-enabled/*; do
    if [ -f "$site" ]; then
        sitename=$(basename "$site")
        sudo cp "$site" "$DUMP_DIR/nginx/${sitename}.conf" 2>/dev/null
        echo "Copied: $sitename"
    fi
done

# Nginx status
sudo nginx -t > "$DUMP_DIR/nginx/nginx-test.txt" 2>&1
sudo systemctl status nginx --no-pager > "$DUMP_DIR/nginx/nginx-status.txt" 2>&1

################################################################################
# DNS DIAGNOSTICS
################################################################################
echo -e "${YELLOW}Running DNS diagnostics...${NC}"

# List of domains to check
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

# DNS resolution checks
echo "=== DNS RESOLUTION CHECKS ===" > "$DUMP_DIR/dns-diagnostics/domain-resolutions.txt"
echo "Date: $(date)" >> "$DUMP_DIR/dns-diagnostics/domain-resolutions.txt"
echo "" >> "$DUMP_DIR/dns-diagnostics/domain-resolutions.txt"

for domain in "${DOMAINS[@]}"; do
    echo "======================================" >> "$DUMP_DIR/dns-diagnostics/domain-resolutions.txt"
    echo "Domain: $domain" >> "$DUMP_DIR/dns-diagnostics/domain-resolutions.txt"
    echo "======================================" >> "$DUMP_DIR/dns-diagnostics/domain-resolutions.txt"
    dig "$domain" >> "$DUMP_DIR/dns-diagnostics/domain-resolutions.txt" 2>&1
    echo "" >> "$DUMP_DIR/dns-diagnostics/domain-resolutions.txt"
    echo "--- nslookup ---" >> "$DUMP_DIR/dns-diagnostics/domain-resolutions.txt"
    nslookup "$domain" >> "$DUMP_DIR/dns-diagnostics/domain-resolutions.txt" 2>&1
    echo "" >> "$DUMP_DIR/dns-diagnostics/domain-resolutions.txt"
    echo "" >> "$DUMP_DIR/dns-diagnostics/domain-resolutions.txt"
done

# Public IP
echo "=== PUBLIC IP ===" > "$DUMP_DIR/dns-diagnostics/public-ip.txt"
curl -s ifconfig.me >> "$DUMP_DIR/dns-diagnostics/public-ip.txt"
echo "" >> "$DUMP_DIR/dns-diagnostics/public-ip.txt"
echo "Date: $(date)" >> "$DUMP_DIR/dns-diagnostics/public-ip.txt"

# Local IP
echo "=== LOCAL IP ===" > "$DUMP_DIR/dns-diagnostics/local-ip.txt"
hostname -I >> "$DUMP_DIR/dns-diagnostics/local-ip.txt"
ip addr show >> "$DUMP_DIR/dns-diagnostics/local-ip.txt"

# Listening ports
echo "=== PORTS 80 & 443 ===" > "$DUMP_DIR/dns-diagnostics/ports-listening.txt"
sudo netstat -tulpn | grep -E ':(80|443)' >> "$DUMP_DIR/dns-diagnostics/ports-listening.txt"
echo "" >> "$DUMP_DIR/dns-diagnostics/ports-listening.txt"
echo "=== ALL LISTENING PORTS ===" >> "$DUMP_DIR/dns-diagnostics/ports-listening.txt"
sudo netstat -tulpn >> "$DUMP_DIR/dns-diagnostics/ports-listening.txt"

# Firewall rules
echo "=== UFW STATUS ===" > "$DUMP_DIR/dns-diagnostics/firewall-rules.txt"
sudo ufw status verbose >> "$DUMP_DIR/dns-diagnostics/firewall-rules.txt"
echo "" >> "$DUMP_DIR/dns-diagnostics/firewall-rules.txt"
echo "=== IPTABLES RULES ===" >> "$DUMP_DIR/dns-diagnostics/firewall-rules.txt"
sudo iptables -L -n -v >> "$DUMP_DIR/dns-diagnostics/firewall-rules.txt"

################################################################################
# NO-IP DDNS STATUS
################################################################################
echo -e "${YELLOW}Collecting No-IP DDNS information...${NC}"

# Service status
systemctl status noip2 --no-pager > "$DUMP_DIR/noip/service-status.txt" 2>&1

# Current No-IP status
sudo noip2 -S > "$DUMP_DIR/noip/current-status.txt" 2>&1

# No-IP configuration (sanitized - remove password if present)
if [ -f /usr/local/etc/no-ip2.conf ]; then
    echo "Configuration file exists at /usr/local/etc/no-ip2.conf" > "$DUMP_DIR/noip/config-info.txt"
    echo "Note: Config file is binary/encoded and contains credentials" >> "$DUMP_DIR/noip/config-info.txt"
fi

# No-IP error logs (last 200 lines)
echo "=== NO-IP RECENT LOGS (last 200 lines) ===" > "$DUMP_DIR/noip/error-logs.txt"
sudo journalctl -u noip2 -n 200 --no-pager >> "$DUMP_DIR/noip/error-logs.txt" 2>&1

# Extract errors only
echo "=== NO-IP ERRORS ONLY ===" > "$DUMP_DIR/noip/errors-only.txt"
sudo journalctl -u noip2 --no-pager | grep -i "error\|fail\|can't\|unable" >> "$DUMP_DIR/noip/errors-only.txt" 2>&1

################################################################################
# PROJECT ECOSYSTEM FILES
################################################################################
echo -e "${YELLOW}Collecting project ecosystem.config.js files...${NC}"

# List of projects
PROJECTS=(
    "acquamarina_website3"
    "memoria_landing"
    "mynewsly_webpage"
    "marzapage"
)

for project in "${PROJECTS[@]}"; do
    # Check for .js first, then .cjs
    ecosystem_js="$HOME/projects/$project/ecosystem.config.js"
    ecosystem_cjs="$HOME/projects/$project/ecosystem.config.cjs"
    
    if [ -f "$ecosystem_js" ]; then
        cp "$ecosystem_js" "$DUMP_DIR/projects/${project}_ecosystem.config.js"
        echo "✓ Copied: $project/ecosystem.config.js"
    elif [ -f "$ecosystem_cjs" ]; then
        cp "$ecosystem_cjs" "$DUMP_DIR/projects/${project}_ecosystem.config.cjs"
        echo "✓ Copied: $project/ecosystem.config.cjs"
    else
        echo "✗ Not found: $project/ecosystem.config.{js,cjs}" > "$DUMP_DIR/projects/${project}_NOT_FOUND.txt"
        echo "⚠ Missing: $project/ecosystem.config.{js,cjs}"
    fi
done

################################################################################
# NETWORK INFORMATION
################################################################################
echo -e "${YELLOW}Collecting network information...${NC}"

# /etc/hosts file
sudo cat /etc/hosts > "$DUMP_DIR/network/etc-hosts.txt" 2>&1

# /etc/resolv.conf
cat /etc/resolv.conf > "$DUMP_DIR/network/resolv.conf.txt" 2>&1

# Network interfaces
ip link show > "$DUMP_DIR/network/network-interfaces.txt"
ip route show > "$DUMP_DIR/network/routes.txt"

# Test localhost
echo "=== LOCALHOST TEST ===" > "$DUMP_DIR/network/localhost-test.txt"
curl -I localhost >> "$DUMP_DIR/network/localhost-test.txt" 2>&1
echo "" >> "$DUMP_DIR/network/localhost-test.txt"
curl -I 127.0.0.1 >> "$DUMP_DIR/network/localhost-test.txt" 2>&1

################################################################################
# MONITORING & HISTORY
################################################################################
echo -e "${YELLOW}Collecting monitoring data...${NC}"

# System uptime
uptime > "$DUMP_DIR/monitoring/uptime.txt"

# Last reboot
last reboot -10 > "$DUMP_DIR/monitoring/recent-reboots.txt"

# System logs for network issues (last 500 lines)
sudo journalctl -n 500 --no-pager | grep -i "network\|dns\|connection" > "$DUMP_DIR/monitoring/network-logs.txt" 2>&1

# Check for IP address changes in No-IP logs
sudo journalctl -u noip2 --no-pager | grep "set to" > "$DUMP_DIR/monitoring/ip-changes.txt" 2>&1

################################################################################
# GENERATE SUMMARY
################################################################################
echo -e "${YELLOW}Generating summary report...${NC}"

cat > "$DUMP_DIR/summary.md" << 'SUMMARY_EOF'
# Raspberry Pi System Dump Summary

**Generated:** $(date)

---

## 🚨 DNS Issue Investigation

### Current Status

**Public IP:** $(cat dns-diagnostics/public-ip.txt | head -1)
**Local IP:** $(hostname -I)
**DDNS Hostname:** dubsy.ddns.net

### Domain DNS Status

SUMMARY_EOF

# Add DNS status for each domain
for domain in "${DOMAINS[@]}"; do
    echo "#### $domain" >> "$DUMP_DIR/summary.md"
    if dig +short "$domain" > /dev/null 2>&1; then
        resolved_ip=$(dig +short "$domain" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
        if [ -z "$resolved_ip" ]; then
            echo "- ❌ **SERVFAIL** - No DNS records found" >> "$DUMP_DIR/summary.md"
        else
            echo "- ✅ Resolves to: $resolved_ip" >> "$DUMP_DIR/summary.md"
        fi
    else
        echo "- ❌ **DNS Resolution Failed**" >> "$DUMP_DIR/summary.md"
    fi
    echo "" >> "$DUMP_DIR/summary.md"
done

cat >> "$DUMP_DIR/summary.md" << SUMMARY_EOF2

---

## 📊 System Status

### PM2 Processes
\`\`\`
$(pm2 list 2>/dev/null || echo "PM2 not running")
\`\`\`

### No-IP DDNS Status
\`\`\`
$(sudo noip2 -S 2>/dev/null || echo "No-IP status unavailable")
\`\`\`

### Recent No-IP Errors
\`\`\`
$(sudo journalctl -u noip2 --no-pager | grep -i "error\|fail\|can't" | tail -10 || echo "No recent errors")
\`\`\`

### Nginx Status
\`\`\`
$(sudo systemctl status nginx --no-pager 2>&1 | head -10)
\`\`\`

---

## 📁 Collected Files

### System
- systemd-services.txt - All system services
- pm2-list.json - PM2 process details
- cron-jobs.txt - All scheduled tasks

### Nginx
- All enabled site configurations
- Nginx test results

### DNS Diagnostics
- domain-resolutions.txt - DNS lookups for all domains
- public-ip.txt - Current public IP
- ports-listening.txt - Open ports
- firewall-rules.txt - UFW and iptables rules

### No-IP
- service-status.txt - No-IP service status
- current-status.txt - Current DDNS configuration
- error-logs.txt - Recent error logs
- errors-only.txt - Filtered errors

### Projects
- ecosystem.config.js for all 6 projects

### Network
- etc-hosts.txt - Local DNS overrides
- resolv.conf.txt - DNS resolver configuration
- network-interfaces.txt - Network interface details

---

## 🔍 Troubleshooting Recommendations

### For Intermittent DNS Failures:

1. **Check No-IP Update Frequency**
   - Currently updates every 30 minutes
   - May not be fast enough if IP changes frequently
   - Consider reducing to 5-10 minutes

2. **Recent No-IP Errors**
   - Check \`noip/errors-only.txt\` for patterns
   - Look for "Can't gethostbyname" errors (network connectivity issues)
   - Look for "Can't get our visible IP" errors (ISP issues)

3. **Domain DNS Configuration**
   - Verify all custom domains point to correct IP or CNAME to dubsy.ddns.net
   - Check DNS TTL settings (low TTL = faster updates but more queries)

4. **Monitor IP Changes**
   - Check \`monitoring/ip-changes.txt\` for IP change history
   - Correlate with DNS failure times

---

## 📈 Next Steps

1. Set up continuous monitoring script to catch next failure
2. Check domain registrar DNS settings for custom domains
3. Consider reducing No-IP update interval
4. Monitor No-IP error logs for patterns

SUMMARY_EOF2

################################################################################
# COMPLETION
################################################################################
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Dump Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "Dump location: ${YELLOW}$DUMP_DIR${NC}"
echo ""
echo "Summary: $DUMP_DIR/summary.md"
echo ""
echo "Directory structure:"
tree -L 2 "$DUMP_DIR" 2>/dev/null || find "$DUMP_DIR" -type d | sed 's|[^/]*/| |g'
echo ""
echo -e "${GREEN}You can now review the dump files or transfer them for analysis.${NC}"
