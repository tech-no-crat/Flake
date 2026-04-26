#!/usr/bin/env bash
# sunshine-diag.sh
# Master script: runs all Sunshine / Tailscale diagnostics and writes a report.
# Usage:
#   ./sunshine-diag.sh              → prints to stdout
#   ./sunshine-diag.sh --save       → also writes sunshine-diag-<timestamp>.log

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAVE_LOG=false
LOG_FILE=""

if [[ "${1:-}" == "--save" ]]; then
    SAVE_LOG=true
    LOG_FILE="$SCRIPT_DIR/sunshine-diag-$(date +%Y%m%d-%H%M%S).log"
fi

BOLD='\033[1m'
RESET='\033[0m'

run_section() {
    local script="$SCRIPT_DIR/$1"
    if [[ ! -x "$script" ]]; then
        echo -e "\n${BOLD}[SKIPPED]${RESET} $1 — not executable or not found (chmod +x scripts/*.sh)"
        return
    fi
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}  Running: $1${RESET}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    bash "$script" || true
}

main() {
    echo -e "${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║       Sunshine Connectivity Diagnostic Suite         ║"
    echo "  ║          $(date '+%Y-%m-%d %H:%M:%S')                     ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo "  Host:   $(hostname)"
    echo "  User:   $(whoami)"
    echo "  Kernel: $(uname -r)"
    echo "  NixOS:  $(nixos-version 2>/dev/null || echo 'unknown')"

    run_section "check-sunshine.sh"
    run_section "check-tailscale.sh"

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}  END OF DIAGNOSTIC${RESET}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    if $SAVE_LOG; then
        echo ""
        echo "  Log saved to: $LOG_FILE"
    fi
}

if $SAVE_LOG; then
    main 2>&1 | tee "$LOG_FILE"
else
    main
fi
