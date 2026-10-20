# dns-doh — dnsmasq with DNS-over-HTTPS upstream

System DNS layout: apps -> `/etc/resolv.conf` (127.0.0.1) -> **dnsmasq** (cache, :53)
-> **dnsproxy** (DoH proxy, 127.0.0.1:5053) -> Cloudflare / Quad9 over HTTPS.

dnsmasq is the main DNS service; dnsproxy (AdGuard, `extra` repo) adds DoH,
because dnsmasq itself cannot speak DoH. systemd-resolved is disabled.

## Files (mirror /etc paths)

| Repo file | Live path |
|-----------|-----------|
| `etc/dnsproxy/dnsproxy.yaml` | `/etc/dnsproxy/dnsproxy.yaml` |
| `etc/dnsmasq.d/10-doh.conf` | `/etc/dnsmasq.d/10-doh.conf` |
| `etc/NetworkManager/NetworkManager.conf` | `/etc/NetworkManager/NetworkManager.conf` |
| `etc/resolv.conf` | `/etc/resolv.conf` |

## Deploy on a fresh machine

```sh
sudo pacman -S dnsproxy dnsmasq      # or via pkgs/install.sh (pkglist.txt)
sudo install -Dm644 etc/dnsproxy/dnsproxy.yaml /etc/dnsproxy/dnsproxy.yaml
sudo install -Dm644 etc/dnsmasq.d/10-doh.conf /etc/dnsmasq.d/10-doh.conf
sudo install -m644 etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf
sudo install -m644 etc/resolv.conf /etc/resolv.conf
```

Then disable the old stack and start the new one:

```sh
sudo systemctl disable --now systemd-resolved systemd-resolved-varlink.socket systemd-resolved-monitor.socket
sudo systemctl enable --now dnsproxy
sudo systemctl restart dnsmasq
```

## nsswitch

Remove the `resolve` NSS module so glibc goes straight to `/etc/resolv.conf`
(dnsmasq) instead of systemd-resolved:

```
hosts: mymachines files myhostname dns
```

## Verify

```sh
dig @127.0.0.1 example.com A        # via dnsmasq -> dnsproxy -> DoH
dig @127.0.0.1 -p 5053 example.com A # via dnsproxy directly
sudo ss -tnp | grep dnsproxy        # live TLS 443 to cloudflare / quad9
```

## Only-DoH guarantee

All resolution goes over HTTPS: dnsmasq's only upstream is the local dnsproxy,
and dnsproxy's only upstreams are `https://cloudflare-dns.com/dns-query` and
`https://dns.quad9.net/dns-query`. The single plaintext element is dnsproxy's
`bootstrap` list (router `192.168.3.1` + `8.8.8.8`) — used only to resolve the
DoH endpoint hostnames, an unavoidable chicken-and-egg. No general DNS query
ever leaves the machine as plaintext.
