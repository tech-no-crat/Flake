#!/usr/bin/env bash
# check-sunshine.sh
# Diagnoses Sunshine game streaming service status, ports, and NixOS module alignment.
# Run as the user that owns the Sunshine session (e.g., shyam), NOT as root.
# For firewall checks you will be prompted for sudo or run with sudo.

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

# ─── Ports Sunshine should use (from NixOS module openFirewall = true) ───────
TCP_PORTS=(47984 47989 47990 48010)
UDP_PORTS=(47998 47999 48000)

# ─── 1. Service status ────────────────────────────────────────────────────────
header "1. Sunshine systemd service"

# NixOS runs sunshine as a user service scoped to the graphical session
SERVICE_UNIT="sunshine.service"

if systemctl --user is-active --quiet "$SERVICE_UNIT" 2>/dev/null; then
    ok "sunshine.service is ACTIVE (user scope)"
else
    fail "sunshine.service is NOT active (user scope)"
    echo ""
    echo "    systemctl --user status sunshine.service output:"
    systemctl --user status "$SERVICE_UNIT" --no-pager 2>&1 | sed 's/^/    /' || true
fi

echo ""
echo "  Full unit status:"
systemctl --user status "$SERVICE_UNIT" --no-pager 2>&1 | head -30 | sed 's/^/    /' || true

# ─── 2. Autostart (enabled at boot/login) ────────────────────────────────────
header "2. Autostart / enabled state"

if systemctl --user is-enabled --quiet "$SERVICE_UNIT" 2>/dev/null; then
    ok "sunshine.service is ENABLED for user session start"
    info "autoStart = true in your NixOS module → this is correct"
else
    ENABLED_STATE=$(systemctl --user is-enabled "$SERVICE_UNIT" 2>/dev/null || echo "unknown")
    warn "sunshine.service enabled state: $ENABLED_STATE"
    info "Your module has autoStart = true — check if the NixOS rebuild was applied"
fi

# ─── 3. Process check ─────────────────────────────────────────────────────────
header "3. Process / PID"

SUNSHINE_PIDS=$(pgrep -a sunshine 2>/dev/null || true)
if [[ -n "$SUNSHINE_PIDS" ]]; then
    ok "Sunshine process found:"
    echo "$SUNSHINE_PIDS" | sed 's/^/    /'
else
    fail "No sunshine process found in process table"
fi

# ─── 4. Listening ports ───────────────────────────────────────────────────────
header "4. Listening ports (expected: TCP ${TCP_PORTS[*]} / UDP ${UDP_PORTS[*]})"

# ss may need root for full info but usually shows own processes
SS_OUT=$(ss -tlunp 2>/dev/null || true)

echo "  TCP ports:"
for port in "${TCP_PORTS[@]}"; do
    if echo "$SS_OUT" | grep -qE ":${port}\b"; then
        PROC=$(echo "$SS_OUT" | grep -E ":${port}\b" | awk '{print $NF}')
        ok "TCP $port is LISTENING  [$PROC]"
    else
        fail "TCP $port is NOT listening"
    fi
done

echo "  UDP ports:"
for port in "${UDP_PORTS[@]}"; do
    if echo "$SS_OUT" | grep -qE ":${port}\b"; then
        PROC=$(echo "$SS_OUT" | grep -E ":${port}\b" | awk '{print $NF}')
        ok "UDP $port is LISTENING  [$PROC]"
    else
        fail "UDP $port is NOT listening"
    fi
done

echo ""
echo "  Full ss output filtered for sunshine ports:"
echo "$SS_OUT" | grep -E ":(47984|47989|47990|47998|47999|48000|48010)\b" | sed 's/^/    /' || echo "    (none matched)"

# ─── 5. NixOS module alignment ────────────────────────────────────────────────
header "5. NixOS module alignment check"

# Check the active system configuration for sunshine
SYSTEM_CONFIG="/run/current-system"

if [[ -d "$SYSTEM_CONFIG" ]]; then
    info "Current system: $(readlink -f $SYSTEM_CONFIG 2>/dev/null | head -c60)"
fi

# Check if openFirewall took effect by looking at nftables/iptables rules
info "Checking firewall rules for Sunshine ports..."

if command -v nft &>/dev/null; then
    echo ""
    echo "  nftables rules mentioning sunshine ports:"
    sudo nft list ruleset 2>/dev/null \
        | grep -E "(47984|47989|47990|47998|47999|48000|48010)" \
        | sed 's/^/    /' \
        || echo "    (no nftables rules found — may require sudo or nftables not in use)"
fi

if command -v iptables &>/dev/null; then
    echo ""
    echo "  iptables rules mentioning sunshine ports:"
    sudo iptables -L INPUT -n --line-numbers 2>/dev/null \
        | grep -E "(47984|47989|47990|47998|47999|48000|48010)" \
        | sed 's/^/    /' \
        || echo "    (none found via iptables)"
fi

# ─── 6. Sunshine config file ──────────────────────────────────────────────────
header "6. Sunshine config file"

SUNSHINE_CONF_CANDIDATES=(
    "$HOME/.config/sunshine/sunshine.conf"
    "/etc/sunshine/sunshine.conf"
    "/var/lib/sunshine/sunshine.conf"
)

FOUND_CONF=false
for f in "${SUNSHINE_CONF_CANDIDATES[@]}"; do
    if [[ -f "$f" ]]; then
        ok "Found config: $f"
        FOUND_CONF=true
        echo ""
        echo "  Relevant settings:"
        grep -E "^(port|address|upnp|origin_web_ui_allowed|key_db)" "$f" 2>/dev/null | sed 's/^/    /' \
            || echo "    (no matching keys — using defaults)"
        echo ""
        echo "  Full config:"
        cat "$f" | sed 's/^/    /'
        break
    fi
done

if ! $FOUND_CONF; then
    warn "No sunshine.conf found in standard locations — using compiled-in defaults"
    info "Default web UI port: 47990 | Streaming ports: see above"
fi

# ─── 7. Recent logs ───────────────────────────────────────────────────────────
header "7. Recent sunshine journal logs (last 50 lines)"

journalctl --user -u sunshine.service --no-pager -n 50 2>/dev/null \
    | sed 's/^/  /' \
    || {
        warn "No user-journal logs found; trying system journal..."
        sudo journalctl -u sunshine.service --no-pager -n 50 2>/dev/null \
            | sed 's/^/  /' \
            || warn "Could not retrieve logs"
    }

# ─── 8. Web UI reachability ───────────────────────────────────────────────────
header "8. Web UI local reachability (https://localhost:47990)"

if command -v curl &>/dev/null; then
    HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 3 https://localhost:47990 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "401" || "$HTTP_CODE" == "302" ]]; then
        ok "Web UI responded with HTTP $HTTP_CODE — Sunshine is reachable locally"
    elif [[ "$HTTP_CODE" == "000" ]]; then
        fail "Web UI did NOT respond (connection refused or timed out)"
    else
        warn "Web UI returned HTTP $HTTP_CODE"
    fi
else
    warn "curl not found; skipping web UI check"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
header "Summary"
echo "  NixOS module settings (from modules/sunshine.nix):"
echo "    enable      = true"
echo "    autoStart   = true"
echo "    capSysAdmin = true"
echo "    openFirewall = true  → should open TCP 47984,47989,47990,48010 & UDP 47998-48000"
echo ""
echo "  If ports are NOT listening → service is not running or crashed"
echo "  If ports ARE listening but you can't connect remotely → see tailscale check:"
echo "    ./check-tailscale.sh"
echo ""
