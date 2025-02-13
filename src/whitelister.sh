#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Clear terminal
clear

# Load helper functions and messages from the template
source <(curl -SskL https://github.com/arian24b/server_management_public/raw/main/template.sh)

# Check for root privileges
CheckPrivileges

# Helper: prompt user with options
choose_option() {
  local prompt="$1"
  shift
  local options=("$@")
  local i=1 choice
  echo "$prompt"
  for option in "${options[@]}"; do
    echo "   $i) $option"
    ((i++))
  done
  read -r -p "Choice: " choice
  echo "$choice"
}

# Get the CDN selection from first argument or prompt the user
if [[ ${1-} == "" ]]; then
  cdnoption=$(choose_option "Select a CDN to add IPs:" "cloudflare" "iranserver" "arvancloud")
else
  cdnoption=$1
fi

clear

# Get the Firewall selection from second argument or prompt the user
if [[ ${2-} == "" ]]; then
  firewalloption=$(choose_option "Select a Firewall to add IPs:" "UFW" "CSF" "firewalld" "iptables" "ipset" "nftables")
else
  firewalloption=$2
fi

clear

# Map CDN selection to name and IP list URL
case "$cdnoption" in
  1|cloudflare)
    CDNNAME="cloudflare"
    IPsLink="https://www.cloudflare.com/ips-v4" # TODO: add IPv6 list if needed
    ;;
  2|iranserver)
    CDNNAME="iranserver"
    IPsLink="https://ips.f95.com/ip.txt"
    ;;
  3|arvancloud)
    CDNNAME="arvancloud"
    IPsLink="https://www.arvancloud.ir/fa/ips.txt"
    ;;
  *)
    abort "The selected CDN is not valid."
    ;;
esac

Normal_msg "Downloading $CDNNAME IPs list..."

# Create temporary file to store downloaded IPs list
IPsFile=$(mktemp /tmp/ar-ips.XXXXXX)
trap 'rm -f "${IPsFile}"' EXIT INT TERM

# Download the IP list using curl or wget
if command -v curl >/dev/null; then
  downloadStatus=$(curl -sSL -w "%{http_code}" -o "${IPsFile}" "${IPsLink}")
elif command -v wget >/dev/null; then
  downloadStatus=$(wget -qO "${IPsFile}" --server-response "${IPsLink}" 2>&1 | awk '/^  HTTP/{print $2}' | tail -n1)
else
  Abort "curl or wget is required to run this script."
fi

if [[ "$downloadStatus" -ne 200 ]]; then
  Abort "Downloading $CDNNAME IP list failed. Status code: ${downloadStatus}"
fi

IPs=$(<"$IPsFile")
Normal_msg "Adding $CDNNAME IPs to the selected Firewall..."

# Process firewall selection
case "$firewalloption" in
  1|ufw)
    if ! command -v ufw >/dev/null; then
      Abort "ufw is not installed."
    fi

    Yellow_msg "Deleting old $CDNNAME rules in ufw"
    # Delete rules that have the CDNNAME in comments
    ufw status numbered | grep "$CDNNAME" | sed 's/^\[\([0-9]*\)\].*/\1/' | sort -rn | while read -r num; do
      ufw --force delete "$num"
    done

    Normal_msg "Adding new $CDNNAME rules to ufw"
    for IP in ${IPs}; do
      ufw allow from "$IP" comment "$CDNNAME"
    done
    ufw reload
    ;;
  2|csf)
    if ! command -v csf >/dev/null; then
      Abort "csf is not installed."
    fi

    Yellow_msg "Deleting old $CDNNAME rules in csf"
    awk '!/'"$CDNNAME"'/' /etc/csf/csf.allow > /tmp/csf.allow.tmp && mv /tmp/csf.allow.tmp /etc/csf/csf.allow

    Normal_msg "Adding new $CDNNAME rules to csf"
    for IP in ${IPs}; do
      csf -a "$IP"
    done
    csf -r
    ;;
  3|firewalld)
    if ! command -v firewall-cmd >/dev/null; then
      Abort "firewalld is not installed."
    fi

    Yellow_msg "Deleting old $CDNNAME zone in firewalld"
    if firewall-cmd --permanent --get-zones | grep -qw "$CDNNAME"; then
      firewall-cmd --permanent --delete-zone="$CDNNAME"
    fi

    Normal_msg "Creating new $CDNNAME zone in firewalld"
    firewall-cmd --permanent --new-zone="$CDNNAME"
    for IP in ${IPs}; do
      firewall-cmd --permanent --zone="$CDNNAME" --add-rich-rule="rule family='ipv4' source address='$IP' port port=80 protocol='tcp' accept"
      firewall-cmd --permanent --zone="$CDNNAME" --add-rich-rule="rule family='ipv4' source address='$IP' port port=443 protocol='tcp' accept"
    done
    firewall-cmd --reload
    ;;
  4|iptables)
    if ! command -v iptables >/dev/null; then
      Abort "iptables is not installed."
    fi

    Yellow_msg "Deleting old $CDNNAME rules in iptables"
    CURRENT_RULES=$(iptables -L INPUT --line-numbers | grep "$CDNNAME" | awk '{print $1}' | sort -rn)
    for rule in $CURRENT_RULES; do
      iptables -D INPUT "$rule"
    done

    Normal_msg "Adding new $CDNNAME rules in iptables"
    for IP in ${IPs}; do
      iptables -A INPUT -s "$IP" -m comment --comment "$CDNNAME" -j ACCEPT
    done
    ;;
  5|ipset)
    if ! command -v ipset >/dev/null; then
      Abort "ipset is not installed."
    fi
    if ! command -v iptables >/dev/null; then
      Abort "iptables is not installed."
    fi

    Yellow_msg "Deleting old $CDNNAME ipset if exists"
    if ipset list | grep -q "^$CDNNAME-ipset"; then
      iptables -D INPUT -m set --match-set "$CDNNAME-ipset" src -j ACCEPT || true
      sleep 0.5
      ipset destroy "$CDNNAME-ipset"
    fi

    Normal_msg "Creating new $CDNNAME ipset"
    ipset create "$CDNNAME-ipset" hash:net
    for IP in ${IPs}; do
      ipset add "$CDNNAME-ipset" "$IP"
    done
    if ! iptables -L INPUT -n | grep -q "$CDNNAME-ipset"; then
      iptables -I INPUT -m set --match-set "$CDNNAME-ipset" src -j ACCEPT
    fi
    ;;
  6|nftables)
    if ! command -v nft >/dev/null; then
      Abort "nftables is not installed."
    fi

    Yellow_msg "Ensuring 'inet filter' table exists"
    if ! nft list tables inet 2>/dev/null | grep -q '^table inet filter'; then
      nft add table inet filter
    fi

    Yellow_msg "Deleting old $CDNNAME chain in nftables"
    if nft list chain inet filter "$CDNNAME" &>/dev/null; then
      nft delete chain inet filter "$CDNNAME"
    fi

    Normal_msg "Creating new $CDNNAME chain in nftables"
    nft add chain inet filter "$CDNNAME" "{ type filter hook input priority 0 \; }"
    IPsString=$(echo "$IPs" | tr '\n' ',' | sed 's/,\s*$//')
    nft add rule inet filter "$CDNNAME" ip saddr "{ $IPsString }" counter accept
    ;;
  *)
    Abort "The selected firewall is not valid."
    ;;
esac

Green_msg "DONE!"
