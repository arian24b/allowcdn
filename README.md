# Whitelist CDN IPs in Your Server Firewall

This project automatically updates your firewall configuration to allow access from various CDN networks. You can run the script manually or schedule it to update the rules regularly.

## How to Use

Run the script and choose your CDN and firewall from the list:

```bash
bash <(curl -sSkL https://github.com/arian24b/allowcdn/raw/main/src/whitelister.sh)
```

After running the script, you will see prompts similar to:

```bash
Select a CDN to add IPs:
   1) cloudflare
   2) iranserver
   3) arvancloud
CDN: [Enter your choice]
```

```bash
Select a firewall to add IPs:
   1) UFW
   2) CSF
   3) firewalld
   4) iptables
   5) ipset+iptables
   6) nftables
Firewall: [Enter your choice]
```

You can also pass the CDN and firewall names directly as arguments:

```bash
bash <(curl -sSkL https://github.com/arian24b/allowcdn/raw/main/src/whitelister.sh) cloudflare ufw
```

## Auto-update Setup

To keep your firewall rules updated automatically, you can create a cron job. For example:

- **Update UFW rules every 6 hours:**

```bash
0 */6 * * * bash <(curl -sSkL https://github.com/arian24b/allowcdn/raw/main/src/whitelister.sh) cloudflare ufw >/dev/null 2>&1
```

- **Update CSF rules every day at 1:00 AM:**

```bash
0 1 * * * bash <(curl -sSkL https://github.com/arian24b/allowcdn/raw/main/src/whitelister.sh) arvancloud csf >/dev/null 2>&1
```

## Supported CDNs

- cloudflare
- arvancloud
- iranserver

## Supported Firewalls

- UFW
- CSF
- firewalld
- iptables
- ipset+iptables
- nftables

## Need More?

If your firewall is not listed, you can open an issue or submit a pull request to add support.
