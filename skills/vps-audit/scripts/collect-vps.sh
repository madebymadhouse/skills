#!/usr/bin/env bash
# Deterministic VPS data collection via SSH. No AI. Called by vps-audit and ops-audit.
# All SSH calls run in parallel. Output is labeled sections.
# Container Coolify UUID suffixes are stripped here — AI gets clean names.
#
# SETUP: Add a "vps" alias to ~/.ssh/config pointing to your server, or set VPS_SSH_TARGET env var.

set -uo pipefail

SSH_TARGET="${VPS_SSH_TARGET:-vps}"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Strip Coolify UUID suffixes from container names.
# Two Coolify patterns: service-UUID-TIMESTAMP (25-UUID, 12-digit ts) and service-UUID (no ts)
SHORTEN='s/-[a-z0-9]\{24\}\(-[0-9]\{12\}\)\{0,1\}//g'

# Fire all SSH calls in parallel — one connection per query, all simultaneous
ssh -q "$SSH_TARGET" "uname -a && grep -E 'PRETTY_NAME|VERSION_ID' /etc/os-release && hostname && uptime" \
  >"$TMP/system" 2>/dev/null &

ssh -q "$SSH_TARGET" "df -h && free -h && echo 'cpus:' \$(nproc) && cat /proc/cpuinfo | grep 'model name' | head -1" \
  >"$TMP/resources" 2>/dev/null &

ssh -q "$SSH_TARGET" "docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | sed '$SHORTEN'" \
  >"$TMP/containers" 2>/dev/null &

ssh -q "$SSH_TARGET" "docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}' | sed '$SHORTEN'" \
  >"$TMP/stats" 2>/dev/null &

ssh -q "$SSH_TARGET" "docker network ls" \
  >"$TMP/networks" 2>/dev/null &

ssh -q "$SSH_TARGET" "echo '--- all ---' && docker volume ls && echo '--- dangling/orphaned ---' && docker volume ls -f dangling=true" \
  >"$TMP/volumes" 2>/dev/null &

ssh -q "$SSH_TARGET" "docker system df" \
  >"$TMP/docker_df" 2>/dev/null &

ssh -q "$SSH_TARGET" "ss -tlnp | grep LISTEN" \
  >"$TMP/ports" 2>/dev/null &

ssh -q "$SSH_TARGET" "ufw status verbose" \
  >"$TMP/firewall" 2>/dev/null &

ssh -q "$SSH_TARGET" "systemctl list-units --state=running --no-pager --type=service" \
  >"$TMP/services" 2>/dev/null &

ssh -q "$SSH_TARGET" "ls /data/coolify/proxy/dynamic/ 2>/dev/null && cat /data/coolify/proxy/dynamic/*.yaml 2>/dev/null" \
  >"$TMP/traefik" 2>/dev/null &

ssh -q "$SSH_TARGET" "echo '=opt'; ls /opt/; echo '=root'; ls /root/; echo '=home'; ls /home/; echo '=passwd'; grep -v -E '(nologin|false)' /etc/passwd" \
  >"$TMP/dirs" 2>/dev/null &

ssh -q "$SSH_TARGET" "tailscale status 2>/dev/null || echo 'tailscale not responding'" \
  >"$TMP/tailscale" 2>/dev/null &

ssh -q "$SSH_TARGET" "last -n 10" \
  >"$TMP/logins" 2>/dev/null &

ssh -q "$SSH_TARGET" "fail2ban-client status 2>/dev/null | head -20 || echo '(fail2ban not available)'" \
  >"$TMP/fail2ban" 2>/dev/null &

wait

# Emit structured output in order
sections=(system resources containers stats networks volumes docker_df ports firewall services traefik dirs tailscale logins fail2ban)
labels=("SYSTEM" "RESOURCES" "CONTAINERS" "CONTAINER_STATS" "NETWORKS" "VOLUMES" "DOCKER_STORAGE" "LISTEN_PORTS" "FIREWALL" "SYSTEMD_SERVICES" "TRAEFIK_ROUTES" "FS_DIRS" "TAILSCALE" "RECENT_LOGINS" "FAIL2BAN")

for i in "${!sections[@]}"; do
  echo "=== ${labels[$i]} ==="
  cat "$TMP/${sections[$i]}" 2>/dev/null || echo "(no output)"
  echo ""
done
