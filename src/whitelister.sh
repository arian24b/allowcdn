#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# Auther: ArianOmrani - https://github.com/arian24b/
# git repository: https://github.com/arian24b/AllowCDN-IPs

set -e
# set -x

clear

# Load Template
source <(curl -SskL https://github.com/arian24b/server_management_public/raw/main/template.sh)

# Check root access
CheckPrivileges

# Use the first argument or Ask the user to select CDN
if [[ -z $1 ]]; then
  echo "Select a CDN to add IPs:"
  echo "   1) cloudflare"
  echo "   2) iranserver"
  echo "   3) arvancloud"
  read -r -p "CDN: " cdnoption
else
  cdnoption=$1
fi

clear

# Use the second argument or Ask the user to select firewall
if [[ -z $2 ]]; then
  echo "Select a Firewall to add IPs:"
  echo "   1) UFW"
  echo "   2) CSF"
  echo "   3) firewalld"
  echo "   4) iptables"
  echo "   5) ipset+iptables"
  echo "   6) nftables"
  read -r -p "Firewall: " firewalloption
else
  firewalloption=$2
fi

clear

# Process user input
case "$cdnoption" in
1 | cloudflare)
  CDNNAME="cloudflare"
  IPsLink="https://www.cloudflare.com/ips-v4" # TODO add ips-v6 https://www.cloudflare.com/ips-v6
  ;;
2 | iranserver)
  CDNNAME="iranserver"
  IPsLink="https://ips.f95.com/ip.txt"
  ;;
3 | arvancloud)
  CDNNAME="arvancloud"
  IPsLink="https://www.arvancloud.ir/fa/ips.txt"
  ;;
*)
  abort "The selected CDN is not valid."
  ;;
esac

Normal_msg "Downloading $CDNNAME IPs list..."

IPsFile=$(mktemp /tmp/ar-ips.XXXXXX)
# Delete the temp file if the script stopped for any reason
trap 'rm -f ${IPsFile}' 0 2 3 15

if [[ -x "$(command -v curl)" ]]; then
  downloadStatus=$(curl "${IPsLink}" -o "${IPsFile}" -L -s -w "%{http_code}\n")
elif [[ -x "$(command -v wget)" ]]; then
  downloadStatus=$(wget "${IPsLink}" -O "${IPsFile}" --server-response 2>&1 | awk '/^  HTTP/{print $2}' | tail -n1)
else
  Abort "curl or wget is required to run this script."
fi

if [[ "$downloadStatus" -ne 200 ]]; then
  Abort "Downloading the $CDNNAME's IP list wasn't successful. status code: ${downloadStatus}"
else
  IPs=$(cat "$IPsFile")
fi

Normal_msg "Adding $CDNNAME's IPs to the selected Firewall..."

# Process user input
case "$firewalloption" in
1 | ufw)
  if [[ ! -x "$(command -v ufw)" ]]; then
    Abort "ufw is not installed."
  fi

  Yellow_msg "Delete old $CDNNAME IPs rules if exist"

  ufw show added | awk '/$CDNNAME/{ gsub("ufw","ufw delete",$0); system($0)}'

  Normal_msg "Adding new $CDNNAME rules"

  for IP in ${IPs}; do
    sudo ufw allow from "$IP" to any comment "$CDNNAME"
  done

  sudo ufw reload
  ;;
2 | csf)
  if [[ ! -x "$(command -v csf)" ]]; then
    Abort "csf is not installed."
  fi

  Yellow_msg "Delete old $CDNNAME IPs rules if exist"
  awk '!/$CDNNAME/' /etc/csf/csf.allow > csf.t && mv csf.t /etc/csf/csf.allow

  Normal_msg "Adding new $CDNNAME rules"
  for IP in ${IPs}; do
    sudo csf -a "$IP"
  done

  sudo csf -r
  ;;
3 | firewalld)
  if [[ ! -x "$(command -v firewall-cmd)" ]]; then
    Abort "firewalld is not installed."
  fi

  Yellow_msg "Delete old $CDNNAME zone if exist"
  if [[ $(sudo firewall-cmd --permanent --list-all-zones | grep $CDNNAME) ]]; then sudo firewall-cmd --permanent --delete-zone=$CDNNAME; fi

  Normal_msg "Adding new $CDNNAME zone"
  sudo firewall-cmd --permanent --new-zone=$CDNNAME
  for IP in ${IPs}; do
    sudo firewall-cmd --permanent --zone=$CDNNAME --add-rich-rule='rule family="ipv4" source address='"$IP"' port port=80 protocol="tcp" accept'
    sudo firewall-cmd --permanent --zone=$CDNNAME --add-rich-rule='rule family="ipv4" source address='"$IP"' port port=443 protocol="tcp" accept'
  done

  sudo firewall-cmd --reload
  ;;
4 | iptables)
  if [[ ! -x "$(command -v iptables)" ]]; then
    Abort "iptables is not installed."
  fi

  Yellow_msg "Delete old $CDNNAME rules if exist"
  CURRENT_RULES=$(iptables --line-number -nL INPUT | grep comment_here | awk '{print $1}' | tac)
  for rule in $CURRENT_RULES; do
    sudo iptables -D INPUT $rule
  done

  Normal_msg "Adding new $CDNNAME rules"
  for IP in ${IPs}; do
    sudo iptables -A INPUT -s "$IP" -m comment --comment "$CDNNAME" -j ACCEPT
  done
  ;;
5 | ipset)
  if [[ ! -x "$(command -v ipset)" ]]; then
    Abort "ipset is not installed."
  fi
  if [[ ! -x "$(command -v iptables)" ]]; then
    Abort "iptables is not installed."
  fi

  Yellow_msg "Delete old $CDNNAME ipset if exist"
  sudo ipset list | grep -q "$CDNNAME-ipset" ; greprc=$?
  if [[ "$greprc" -eq 0 ]]; then
    sudo iptables -D INPUT -m set --match-set $CDNNAME-ipset src -j ACCEPT 2>/dev/null
    sleep 0.5
    sudo ipset destroy $CDNNAME-ipset
  fi

  Normal_msg "Adding new $CDNNAME ipset"
  ipset create $CDNNAME-ipset hash:net
  for IP in ${IPs}; do
    ipset add $CDNNAME-ipset "$IP"
  done
  sudo iptables -nvL | grep -q "$CDNNAME-ipset"; exitcode=$?
  if [[ "$exitcode" -eq 1 ]]; then
    sudo iptables -I INPUT -m set --match-set $CDNNAME-ipset src -j ACCEPT
  fi
  ;;
6 | nftables)
  if [[ ! -x "$(command -v nft)" ]]; then
    Abort "nftables is not installed."
  fi
  # create filter table
  nft add table inet filter

  Yellow_msg "Delete old $CDNNAME chain if exist"
  if [[ $(sudo nft list ruleset | grep $CDNNAME) ]]; then sudo nft delete chain inet filter $CDNNAME; fi

  Normal_msg "Adding new $CDNNAME chain"
  sudo nft add chain inet filter $CDNNAME '{ type filter hook input priority 0; }'
  # concat all IPs to a string and remove blank line and separate with comma
  IPsString=$(echo "$IPs" | tr '\n' ',' | sed 's/,$//')
  sudo nft insert rule inet filter $CDNNAME counter ip saddr "{ $IPsString }" accept
  ;;
*)
  Abort "The selected firewall is not valid."
  ;;
esac

Green_msg "DONE!"
