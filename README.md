# White-List CDN's IPs in firewall


This project modifies your firewall configuration to allow many CDN's IP network access to your server.

You can also schedule this script to update the firewall rules automatically.

## How to use

Just run the script and select your CDN and Firewall from the list:

```bash
bash <(curl -sSkL https://github.com/arian24b/AllowCDN-IPs/raw/main/src/whitelister.sh)
```
```bash
Select a CDN to add IPs:
   1) cloudflare
   2) iranserver
   3) arvancloud
CDN: [YOUR INPUT]
```
```bash
Select a firewall to add IPs:
   1) UFW
   2) CSF
   3) firewalld
   4) iptables
   5) ipset+iptables
   6) nftables
Firewall: [YOUR INPUT]
```

Also, you can pass the CDN's name and Firewall's name in arguments:

```bash
bash <(curl -sSkL https://github.com/arian24b/AllowCDN-IPs/raw/main/src/whitelister.sh) cloudflare ufw
```

### Auto-update

You can create a cronjob to update the rules automatically.

Examples:

* Update UFW rules every 6 hours

```bash
0 */6 * * * bash <(curl -sSkL https://github.com/arian24b/AllowCDN-IPs/raw/main/src/whitelister.sh) cloudflare ufw >/dev/null 2>&1
```

* Update CSF rules every day at 1:00

```bash
0 1 * * * bash <(curl -sSkL https://github.com/arian24b/AllowCDN-IPs/raw/main/src/whitelister.sh) arvancloud csf >/dev/null 2>&1
```

## Supported CDNs

We currently support these CDN:

* cloudflare
* arvancloud
* iranserver


## Supported firewalls

We currently support these firewalls:

* UFW
* CSF
* firewalld
* iptables
* ipset+iptables
* nftables

### Need more?

If you use a firewall that is not listed here, you can:

* Create an issue
* Send a pull request
