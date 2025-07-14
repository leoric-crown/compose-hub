#!/usr/bin/env bash
set -euo pipefail

# ---------------------------- Script Directory ----------------------------
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# ---------------------------- Logging Setup ----------------------------
LOG_FILE="$SCRIPT_DIR/ollama-config-audit-$(date +%Y%m%dT%H%M%S).log"

# Simple logger: timestamped, writes to stdout and log file
log() {
  local ts; ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "${ts} - $*" | tee -a "$LOG_FILE"
}

# Trap errors and log before exit
trap 'log "ERROR: An error occurred on line ${LINENO}. Exiting."; exit 1' ERR

# ------------------------- Location Variables -------------------------
USER_CONFIG="$HOME/.config/ollama/config.toml"
SYSTEM_CONFIG="/etc/ollama/config.toml"
SERVICE_UNIT="/etc/systemd/system/ollama.service"
OVERRIDE_DIR="/etc/systemd/system/ollama.service.d"
DATA_DIR="$HOME/.ollama"
ENV_FILE="$SCRIPT_DIR/ollama-env-$(date +%Y%m%dT%H%M%S).txt"

log "Starting Ollama config audit."
log "Log file: $LOG_FILE"

# ------------------------- Audit Phase -------------------------
log "Checking user config at $USER_CONFIG"
if [ -f "$USER_CONFIG" ]; then
  log "Found user config, dumping contents:"
  cat "$USER_CONFIG" | tee -a "$LOG_FILE"
else
  log "No user config found (using defaults)."
fi

log "Checking system config at $SYSTEM_CONFIG"
if [ -f "$SYSTEM_CONFIG" ]; then
  log "Found system config, dumping contents:"
  cat "$SYSTEM_CONFIG" | tee -a "$LOG_FILE"
else
  log "No system-wide config found."
fi

log "Capturing Ollama environment variables to $ENV_FILE"
env | grep -E '^OLLAMA_' | tee "$ENV_FILE" | tee -a "$LOG_FILE" || log "No OLLAMA_ variables set."

log "Inspecting systemd unit $SERVICE_UNIT"
if systemctl list-unit-files | grep -q '^ollama.service'; then
  log "Ollama service found, unit file contents:"
  systemctl cat ollama.service | tee -a "$LOG_FILE"
else
  log "Ollama service not registered."
fi

log "Inspecting override directory $OVERRIDE_DIR"
if [ -d "$OVERRIDE_DIR" ]; then
  log "Override directory exists, listing files:"
  ls -l "$OVERRIDE_DIR" | tee -a "$LOG_FILE"
  log "Dumping override.conf contents:"
  cat "$OVERRIDE_DIR/override.conf" | tee -a "$LOG_FILE"
else
  log "No override directory present."
fi

log "Checking data directory $DATA_DIR"
if [ -d "$DATA_DIR" ]; then
  log "Data directory size and structure:"
  du -sh "$DATA_DIR" | tee -a "$LOG_FILE"
  ls -R "$DATA_DIR" | tee -a "$LOG_FILE"
else
  log "Data directory not present."
fi

# ------------------------- Packaging Phase -------------------------
ARCHIVE="$SCRIPT_DIR/ollama-config-$(date +%Y%m%dT%H%M%S)-full.tar.gz"
log "Preparing file list for archive"

# Build list of existing items
FILES=()
for p in "$USER_CONFIG" "$SYSTEM_CONFIG" "$SERVICE_UNIT" "$OVERRIDE_DIR" "$ENV_FILE" "$DATA_DIR"; do
  if [ -e "$p" ]; then
    FILES+=("$p")
  else
    log "Skipping missing path: $p"
  fi
done

log "Creating archive $ARCHIVE"
tar czvf "$ARCHIVE" \
  --transform="s|^|ollama-backup/|" \
  --ignore-failed-read \
  "${FILES[@]}" | tee -a "$LOG_FILE"

log "Audit complete. Archive created at: $ARCHIVE"
log "Full details in log file: $LOG_FILE"
