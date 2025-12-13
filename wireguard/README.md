# WireGuard Docker Compose (1 Host + 4 Client Servers)

This repository provides a deterministic, explicit WireGuard configuration using Docker Compose:

- **VPN host (server)**: runs WireGuard + Prometheus exporter
- **4 client servers**: each runs a WireGuard client that connects to the host

## Non-negotiables (read this before you deploy)

1. **WireGuard is a kernel interface.** Docker is not abstracting that away. Your host kernel must support WireGuard.
2. **Routing and firewall rules are the real system.** If you get `AllowedIPs`, forwarding, or firewall wrong, the tunnel will look “up” and still not move traffic.
3. **WireGuard configs do not expand environment variables.** If you enable NAT in `wg0.conf`, hardcode the egress interface (e.g., `eth0`).

## Layout

- `host/` VPN host stack
- `clients/client1..client4/` Client stacks
- `scripts/genkeys.sh` Key generation helper

## 1) Generate keys

On any Linux machine with `wg` installed:

```bash
cd scripts
./genkeys.sh server
./genkeys.sh client1
./genkeys.sh client2
./genkeys.sh client3
./genkeys.sh client4
```

You will get for each name:

- `<name>.privatekey`
- `<name>.publickey`
- `<name>.presharedkey`

## 2) Configure the VPN host

### 2.1 Set env

Edit `host/.env`:

- `WG_SERVER_ENDPOINT`: public DNS/IP
- `WG_PORT`: UDP port
- `WG_SUBNET_CIDR`: e.g. `10.13.13.0/24`
- `WG_EGRESS_IFACE`: only if enabling NAT

### 2.2 Edit host WireGuard config

Edit `host/config/wg_confs/wg0.conf`:

- Set server `PrivateKey`
- For each peer:
  - Set client `PublicKey`
  - Set `PresharedKey`
  - Set `AllowedIPs`

#### AllowedIPs: two common models

**Model A — private routing only (recommended for server-to-server):**

- Keep client `AllowedIPs = 10.13.13.0/24`
- Server peers: `AllowedIPs = 10.13.13.1x/32`

**Model B — full tunnel (risky):**

- Client `AllowedIPs = 0.0.0.0/0, ::/0`
- Server must do NAT (`PostUp`/`PostDown`) and you accept the host as a chokepoint

### 2.3 Firewall / port forwarding

- Allow inbound UDP `WG_PORT` on the VPN host
- If behind NAT, port-forward UDP `WG_PORT` to the VPN host

## 3) Configure each client server

For each client directory (`clients/client1` .. `client4`):

1. Edit `config/wg_confs/wg0.conf`
   - `PrivateKey`: that client’s private key
   - `PresharedKey`: that client’s PSK
   - `PublicKey`: server public key
   - `Endpoint`: `WG_SERVER_ENDPOINT:WG_PORT`

2. Start the client:

```bash
cd clients/client1
docker compose up -d
```

Repeat for client2..client4.

## 4) Start the VPN host

```bash
cd host
docker compose up -d
```

## 5) Verify

On host:

```bash
wg show
```

On each client:

```bash
wg show
ping -c 3 10.13.13.1
```

If `wg show` looks fine but traffic doesn’t move, your issue is almost always:

- incorrect `AllowedIPs`
- missing IP forwarding
- firewall rules blocking FORWARD
- MTU problems

## 6) Metrics (Prometheus)

The stack includes `wireguard_exporter` bound to the host network.

Default target:

- `VPN_HOST_IP:9586`

Prometheus snippet:

```yaml
scrape_configs:
  - job_name: wireguard
    static_configs:
      - targets: ["VPN_HOST_IP:9586"]
```

Suggested alert logic:

- alert if `now - latest_handshake > N minutes` per peer

## Notes on secrets

You will see `secrets/` folders. They are placeholders.

Practical reality: WireGuard expects keys in the config file. If you want Docker secrets, you must template `wg0.conf` at container start.
That adds complexity and failure modes. Only do it if you have a compliance reason.

## Hardening recommendations

- Run the VPN host on a minimal OS and keep it patched.
- Restrict UDP `WG_PORT` exposure to expected source IPs if possible.
- Use PSKs for each peer (already supported in these templates).
- Do not run “full tunnel” unless you actually need it.
