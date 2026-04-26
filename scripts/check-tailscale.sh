#!/usr/bin/env bash
# check-tailscale.sh
# Investigates whether Tailscale is interfering with Sunshine connectivity.
#
# How Tailscale can break Sunshine:
#  1. Tailscale sets itself as the default route → LAN clients use wrong path
#  2. Tailscale's DNS (MagicDNS / 100.100.100.100) shadows mDNS / local resolution
#  3. Tailscale ACLs block the Moonlight client from reaching Sunshine ports
#  4. The NixOS firewall applies rules PER INTERFACE — Tailscale's tailscale0
#     interface does NOT inherit openFirewall rules unless explicitly allowed
#  5. Sunshine binds to 0.0.0.0 but the Moonlight client's traffic arrives on
#     tailscale0 — iptables/nftables INPUT chain may drop it
#
# Run as normal user; some checks need sudo.

set -euo pipefail

BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${RESET}    $*"; }
warn() { echo -e "  ${YELLOW}[WARN]${RESET}  $*"; }
fail() { echo -e "  ${RED}[FAIL]${RESET}  $*"; }
info() { echo -e "  ${CYAN}[INFO]${RESET}  $*"; }
header() { echo -e "\n${BOLD}=== $* ===${RESET}"; }

TCP_PORTS=(47984 47989 47990 48010)
UDP_PORTS=(47998 47999 48000)

# ─── 1. Is Tailscale running? ─────────────────────────────────────────────────
header "1. Tailscale service status"

if systemctl is-active --quiet tailscaled 2>/dev/null; then
    warn "tailscaled is ACTIVE — Tailscale is running (potential interference)"
else
    ok "tailscaled is NOT active"
    echo "  Tailscale is not running — it is not the cause of your problem."
    echo "  Re-run check-sunshine.sh to continue diagnosing."
    exit 0
fi

echo ""
echo "  tailscaled status:"
systemctl status tailscaled --no-pager 2>&1 | head -20 | sed 's/^/    /'

# ─── 2. Tailscale network info ────────────────────────────────────────────────
header "2. Tailscale network info"

if command -v tailscale &>/dev/null; then
    echo "  tailscale status:"
    tailscale status 2>/dev/null | sed 's/^/    /' || warn "Could not run tailscale status"

    echo ""
    echo "  tailscale ip:"
    tailscale ip 2>/dev/null | sed 's/^/    /' || warn "Could not get Tailscale IP"

    echo ""
    echo "  tailscale netcheck (reachability diagnostics):"
    tailscale netcheck 2>/dev/null | sed 's/^/    /' || warn "tailscale netcheck failed"
else
    warn "tailscale CLI not found in PATH"
fi

# ─── 3. Network interfaces ────────────────────────────────────────────────────
header "3. Network interfaces (looking for tailscale0)"

ip -brief addr show 2>/dev/null | sed 's/^/  /' || true

echo ""
if ip link show tailscale0 &>/dev/null; then
    warn "tailscale0 interface EXISTS"
    echo ""
    TS_IP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}')
    info "Tailscale IP on this machine: $TS_IP"
    info "Moonlight clients on Tailscale must connect to: $TS_IP"
else
    ok "tailscale0 interface does NOT exist (Tailscale fully stopped)"
fi

# ─── 4. Routing table ─────────────────────────────────────────────────────────
header "4. Routing table — is Tailscale a default route?"

echo "  IPv4 routes:"
ip route show 2>/dev/null | sed 's/^/    /'

DEFAULT_VIA=$(ip route show default 2>/dev/null | head -1 || true)
if echo "$DEFAULT_VIA" | grep -q tailscale; then
    fail "Tailscale IS the default gateway! → LAN traffic may be misrouted"
    info "Fix: set accept_routes = false in Tailscale, or check subnet routing settings"
else
    ok "Default route does NOT go through Tailscale"
    echo "  Default: $DEFAULT_VIA"
fi

# ─── 5. Firewall rules — tailscale0 interface ─────────────────────────────────
header "5. Firewall: does tailscale0 get the Sunshine ports?"

info "NixOS openFirewall = true opens ports in the INPUT chain, but ONLY for"
info "interfaces that pass through the standard filter chain. Tailscale's"
info "interface may or may not be covered depending on NixOS version."
echo ""

if command -v nft &>/dev/null; then
    echo "  --- nftables ruleset (sunshine-relevant sections) ---"
    sudo nft list ruleset 2>/dev/null | grep -E -A2 -B2 \
        "(47984|47989|47990|47998|47999|48000|48010|tailscale|sunshine)" \
        | sed 's/^/  /' \
        || echo "  (no matches or requires sudo)"

    echo ""
    echo "  --- Full INPUT chain (if nftables is used) ---"
    sudo nft list chain inet nixos-fw input 2>/dev/null | sed 's/^/  /' \
        || sudo nft list chain ip filter INPUT 2>/dev/null | sed 's/^/  /' \
        || echo "  (chain not found with those names)"
fi

if command -v iptables &>/dev/null; then
    echo ""
    echo "  --- iptables INPUT chain ---"
    sudo iptables -L INPUT -n -v --line-numbers 2>/dev/null | sed 's/^/  /' \
        || echo "  (requires sudo)"
fi

# ─── 6. Sunshine port reachability via tailscale IP ───────────────────────────
header "6. Sunshine ports reachable on Tailscale IP?"

if ! ip link show tailscale0 &>/dev/null; then
    info "tailscale0 not up — skipping this check"
else
    TS_IP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    if [[ -z "$TS_IP" ]]; then
        warn "Could not determine Tailscale IP"
    else
        echo "  Testing TCP ports on Tailscale IP $TS_IP..."
        for port in "${TCP_PORTS[@]}"; do
            if timeout 2 bash -c "echo >/dev/tcp/$TS_IP/$port" 2>/dev/null; then
                ok "TCP $port reachable via $TS_IP"
            else
                fail "TCP $port NOT reachable via $TS_IP (firewall blocking tailscale0?)"
            fi
        done
    fi
fi

# ─── 7. Sunshine port reachability on LAN IP ──────────────────────────────────
header "7. Sunshine ports reachable on primary LAN IP?"

LAN_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || true)
if [[ -n "$LAN_IP" ]]; then
    info "Primary LAN source IP appears to be: $LAN_IP"
    echo ""
    echo "  Testing TCP ports on LAN IP $LAN_IP..."
    for port in "${TCP_PORTS[@]}"; do
        if timeout 2 bash -c "echo >/dev/tcp/$LAN_IP/$port" 2>/dev/null; then
            ok "TCP $port reachable via $LAN_IP"
        else
            fail "TCP $port NOT reachable via $LAN_IP"
        fi
    done
else
    warn "Could not determine LAN IP"
fi

# ─── 8. MagicDNS / DNS interference ──────────────────────────────────────────
header "8. DNS — is Tailscale MagicDNS overriding local resolution?"

echo "  /etc/resolv.conf:"
cat /etc/resolv.conf 2>/dev/null | sed 's/^/    /' || true

echo ""
echo "  systemd-resolved status:"
resolvectl status 2>/dev/null | head -30 | sed 's/^/    /' \
    || systemd-resolve --status 2>/dev/null | head -30 | sed 's/^/    /' \
    || warn "Could not get resolved status"

echo ""
# Check if Tailscale has injected 100.100.100.100 as DNS
if grep -q "100.100.100.100" /etc/resolv.conf 2>/dev/null || \
   resolvectl status 2>/dev/null | grep -q "100.100.100.100"; then
    warn "Tailscale MagicDNS (100.100.100.100) is active as a DNS server"
    info "This overrides mDNS and may prevent Moonlight from resolving this host by name"
    info "On Moonlight: add the host by IP address directly, not by hostname"
else
    ok "Tailscale MagicDNS does not appear to be the active DNS resolver"
fi

# ─── 9. Tailscale ACLs (if accessible) ───────────────────────────────────────
header "9. Tailscale serve / funnel (is sunshine exposed)?"

if command -v tailscale &>/dev/null; then
    echo "  tailscale serve status:"
    tailscale serve status 2>/dev/null | sed 's/^/    /' || info "(serve not configured)"
fi

# ─── 10. Diagnosis summary ────────────────────────────────────────────────────
header "10. Diagnosis & Recommendations"

cat <<'EOF'
  SCENARIO A — You want LAN-only Moonlight (same Wi-Fi/LAN, no Tailscale):
  ─────────────────────────────────────────────────────────────────────────
  • Tailscale should NOT affect LAN connectivity IF the default route is not
    through Tailscale (check section 4 above).
  • If nftables INPUT rules don't include Sunshine ports → openFirewall may
    not have applied. Try: sudo nixos-rebuild switch
  • Make sure Moonlight is given the LAN IP shown in section 7.

  SCENARIO B — You want Moonlight over Tailscale (remote / VPN):
  ──────────────────────────────────────────────────────────────
  • Moonlight must connect to the Tailscale IP (100.x.x.x), not LAN IP.
  • The NixOS firewall WILL block Tailscale traffic unless you add:
      networking.firewall.trustedInterfaces = [ "tailscale0" ];
    (or manually allow the ports on tailscale0)
  • Add to hosts/default/configuration.nix or hosts/nixos/configuration.nix:
      networking.firewall.trustedInterfaces = [ "tailscale0" ];
  • After adding, rebuild: sudo nixos-rebuild switch

  SCENARIO C — Sunshine is not running at all:
  ─────────────────────────────────────────────
  • Check section 1 output above.
  • User services only start when the user is logged in (graphical session).
  • If you need headless autostart, you need a system-level service or linger:
      sudo loginctl enable-linger <your-username>

EOF
