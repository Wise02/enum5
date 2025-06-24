#!/usr/bin/env bash
# enum5.sh - Powerful Subdomain Enumeration & Screenshot Script
# Version: 3.0

set -euo pipefail

#-----------------------------
# Configurable Defaults
#-----------------------------
SCRIPT_VERSION="3.0"
DEFAULT_TIMEOUT=120
DEFAULT_THREADS=10
DEFAULT_LOGFILE="enum5.log"
DEFAULT_OUTPUT_DIR="$PWD"
KEEP_OLD=0
TAKE_SCREENSHOTS=1
VERBOSE=0

#-----------------------------
# Color Functions
#-----------------------------
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"
BOLD="\033[1m"

log() { echo -e "${CYAN}[$(date '+%H:%M:%S')]${RESET} $*" | tee -a "$LOGFILE"; }
info() { echo -e "${GREEN}[+]${RESET} $*" | tee -a "$LOGFILE"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*" | tee -a "$LOGFILE"; }
err() { echo -e "${RED}[✗]${RESET} $*" | tee -a "$LOGFILE"; }
debug() { [[ $VERBOSE -eq 1 ]] && echo -e "${BLUE}[DEBUG]${RESET} $*" | tee -a "$LOGFILE"; }

#-----------------------------
# Banner
#-----------------------------
banner() {
  echo -e "${BOLD}${CYAN}"
  echo "   ______                 _____  "
  echo "  / ____/___  ____  ___  / __/ /_"
  echo " / / __/ __ \/ __ \/ _ \/ /_/ __/"
  echo "/ /_/ / /_/ / /_/ /  __/ __/ /_  "
  echo "\____/\____/ .___/\___/_/  \__/  "
  echo "          /_/                    "
  echo "${RESET}"
  echo "${BOLD}enum5.sh v$SCRIPT_VERSION - Subdomain Enumeration & Screenshot Automation${RESET}"
  echo
}

#-----------------------------
# Usage
#-----------------------------
usage() {
  cat <<EOF
Usage: $0 [options] <domain-or-URL>

Options:
  --help                Show this help message and exit
  --version             Show script version and exit
  --no-screenshots      Skip screenshotting step
  --threads N           Set concurrency for tools (default: $DEFAULT_THREADS)
  --timeout N           Set per-tool timeout in seconds (default: $DEFAULT_TIMEOUT)
  --logfile FILE        Set log file (default: $DEFAULT_LOGFILE)
  --output-dir DIR      Set base output directory (default: current dir)
  --verbose             Enable verbose/debug output
  --keep-old            Keep old output files (do not overwrite)

Examples:
  $0 example.com
  $0 --no-screenshots --threads 20 --timeout 60 example.com
EOF
  exit 0
}

#-----------------------------
# Parse Args
#-----------------------------
ARGS=()
THREADS=$DEFAULT_THREADS
TIMEOUT=$DEFAULT_TIMEOUT
LOGFILE=$DEFAULT_LOGFILE
OUTPUT_DIR=$DEFAULT_OUTPUT_DIR
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help) usage ;;
    --version) echo "enum5.sh v$SCRIPT_VERSION"; exit 0 ;;
    --no-screenshots) TAKE_SCREENSHOTS=0; shift ;;
    --threads) THREADS="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --logfile) LOGFILE="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --verbose) VERBOSE=1; shift ;;
    --keep-old) KEEP_OLD=1; shift ;;
    -*) err "Unknown flag: $1"; usage ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

[[ ${#ARGS[@]} -eq 1 ]] || usage
domain="${ARGS[0]}"

#-----------------------------
# Helper: Strip protocol & trailing slash
#-----------------------------
sanitize() {
  local d="$1"
  d="${d#http://}"
  d="${d#https://}"
  d="${d%/}"
  echo "$d"
}

domain=$(sanitize "$domain")
base="$OUTPUT_DIR/$domain"
recon="$base/recon"
final="$recon/final"
screenshots="$final/screenshots"

#-----------------------------
# Check Internet
#-----------------------------
if ! ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
  err "No internet connectivity. Exiting."
  exit 1
fi

#-----------------------------
# Check Tools
#-----------------------------
need_tool() {
  if ! command -v "$1" &>/dev/null; then
    err "$1 not found. Please install: $2"
    echo -e "${YELLOW}Install command:${RESET} $3"
    exit 1
  fi
}
need_tool subfinder "https://github.com/projectdiscovery/subfinder" "go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
need_tool amass "https://github.com/owasp-amass/amass" "go install github.com/owasp-amass/amass/v4/...@latest"
need_tool assetfinder "https://github.com/tomnomnom/assetfinder" "go install github.com/tomnomnom/assetfinder@latest"
need_tool httprobe "https://github.com/tomnomnom/httprobe" "go install github.com/tomnomnom/httprobe@latest"
need_tool sublist3r "https://github.com/aboul3la/Sublist3r" "pip install sublist3r"
if [[ $TAKE_SCREENSHOTS -eq 1 ]]; then
  need_tool eyewitness "https://github.com/FortyNorthSecurity/EyeWitness" "sudo apt install eyewitness"
fi

#-----------------------------
# Prepare Output Dirs
#-----------------------------
if [[ $KEEP_OLD -eq 0 ]]; then
  rm -rf "$base"
fi
mkdir -p "$recon" "$final" "$screenshots"

#-----------------------------
# Paths for our files
#-----------------------------
subf="$recon/subfinder.txt"
amas="$recon/amass.txt"
asso="$recon/assetfinder.txt"
merged="$final/final.txt"
sorted="$final/sorted_final.txt"
live="$final/live_domains.txt"
subli="$recon/sublist3r.txt"
log "Logging to $LOGFILE"
: > "$LOGFILE"

#-----------------------------
# Subfinder
#-----------------------------
info "Enumerating subdomains with Subfinder..."
if ! timeout $TIMEOUT subfinder -d "$domain" -o "$subf" -t "$THREADS" 2>>"$LOGFILE"; then
  warn "Subfinder timed out or failed."
fi
if [[ -s "$subf" ]]; then
  cat "$subf" >> "$merged"
  debug "Subfinder found $(wc -l < "$subf") subdomains."
else
  warn "Subfinder output is empty."
fi

#-----------------------------
# Amass
#-----------------------------
info "Enumerating subdomains with Amass..."
if ! timeout $TIMEOUT amass enum -d "$domain" -o "$amas" 2>>"$LOGFILE"; then
  warn "Amass timed out or failed."
fi
if [[ -s "$amas" ]]; then
  cat "$amas" >> "$merged"
  debug "Amass found $(wc -l < "$amas") subdomains."
else
  warn "Amass output is empty."
fi

#-----------------------------
# Assetfinder
#-----------------------------
info "Enumerating subdomains with Assetfinder..."
if ! timeout $TIMEOUT assetfinder --subs-only "$domain" > "$asso" 2>>"$LOGFILE"; then
  warn "Assetfinder timed out or failed."
fi
if [[ -s "$asso" ]]; then
  cat "$asso" >> "$merged"
  debug "Assetfinder found $(wc -l < "$asso") subdomains."
else
  warn "Assetfinder output is empty."
fi

#-----------------------------
# Sublist3r
#-----------------------------
info "Enumerating subdomains with Sublist3r..."
if ! timeout $TIMEOUT sublist3r -d "$domain" -o "$subli" 2>>"$LOGFILE"; then
  warn "Sublist3r timed out or failed."
fi
if [[ -s "$subli" ]]; then
  cat "$subli" >> "$merged"
  debug "Sublist3r found $(wc -l < "$subli") subdomains."
else
  warn "Sublist3r output is empty."
fi

#-----------------------------
# Deduplicate
#-----------------------------
info "Deduplicating subdomains..."
sort -u "$merged" -o "$sorted"

#-----------------------------
# Httprobe
#-----------------------------
info "Checking live domains with httprobe..."
if ! timeout $TIMEOUT httprobe -prefer-https -c "$THREADS" < "$sorted" > "$live" 2>>"$LOGFILE"; then
  warn "Httprobe timed out or failed."
fi
if [[ -s "$live" ]]; then
  debug "Httprobe found $(wc -l < "$live") live hosts."
else
  warn "No live domains found (live_domains.txt is empty)."
fi

#-----------------------------
# EyeWitness Screenshots
#-----------------------------
EYEWITNESS_RAN=0
if [[ $TAKE_SCREENSHOTS -eq 1 ]]; then
  if command -v eyewitness &>/dev/null; then
    info "Taking screenshots with EyeWitness..."
    read -p "Do you want to use --no-sandbox with EyeWitness? [y/N]: " EYEWITNESS_SANDBOX
    if [[ "$EYEWITNESS_SANDBOX" =~ ^[Yy]$ ]]; then
      if ! eyewitness --web -f "$live" -d "$screenshots" --no-prompt --no-sandbox 2>>"$LOGFILE"; then
        warn "EyeWitness failed."
      else
        EYEWITNESS_RAN=1
      fi
    else
      if ! eyewitness --web -f "$live" -d "$screenshots" --no-prompt 2>>"$LOGFILE"; then
        warn "EyeWitness failed."
      else
        EYEWITNESS_RAN=1
      fi
    fi
    debug "EyeWitness screenshots directory after: $(ls -1 "$screenshots" 2>/dev/null | wc -l) files."
    if [[ -d "$screenshots" && -n "$(ls -A "$screenshots" 2>/dev/null)" ]]; then
      debug "EyeWitness screenshots saved in $screenshots."
    else
      warn "Screenshots directory is still empty after EyeWitness."
    fi
  else
    warn "EyeWitness is not installed. Skipping screenshots."
  fi
fi

#-----------------------------
# Summary
#-----------------------------
info "Done!"
echo "  • Raw outputs:    $subf, $amas, $asso, $subli"
echo "  • Merged list:   $merged"
echo "  • Deduped list:  $sorted"
echo "  • Live hosts:    $live"
echo "  • Screenshots:   $screenshots"

# Count stats
sub_count=$(wc -l < "$sorted" 2>/dev/null || echo 0)
live_count=$(wc -l < "$live" 2>/dev/null || echo 0)
screen_count=$(ls "$screenshots" 2>/dev/null | wc -l || echo 0)

echo
echo "[+] Subfinder:      $( [[ -s "$subf" ]] && echo Ran || echo Skipped )"
echo "[+] Amass:          $( [[ -s "$amas" ]] && echo Ran || echo Skipped )"
echo "[+] Assetfinder:    $( [[ -s "$asso" ]] && echo Ran || echo Skipped )"
echo "[+] Httprobe:       $( [[ -s "$live" ]] && echo Ran || echo Skipped )"
echo "[+] EyeWitness:     $( [[ $EYEWITNESS_RAN -eq 1 ]] && echo Ran || echo Skipped )"
echo "[+] Sublist3r:      $( [[ -s "$subli" ]] && echo Ran || echo Skipped )"
echo "[+] Unique subdomains: $sub_count"
echo "[+] Live hosts:        $live_count"
if [[ $TAKE_SCREENSHOTS -eq 1 ]]; then
echo "[+] Screenshots:       $screen_count"
fi

echo
info "Next steps:"
echo "- Review $LOGFILE for errors or details."
echo "- Check $screenshots for screenshots."
echo "- Use the merged and deduped lists for further recon."
echo "- Try --help for more options."