#!/usr/bin/env bash
#
# kali-check.sh — verify every tool, wordlist and config the Deep Recon Runbook
# depends on is present and runnable.
#
# Usage:
#   ./kali-check.sh              full report
#   ./kali-check.sh --quiet      only show what is missing
#   ./kali-check.sh --versions   include version strings (slower)
#
# Exit status: 0 = everything present, 1 = something missing.

set -uo pipefail

QUIET=0
VERSIONS=0
for a in "$@"; do
  case "$a" in
    -q|--quiet)    QUIET=1 ;;
    -v|--versions) VERSIONS=1 ;;
    -h|--help)     sed -n '3,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

if [ -t 1 ]; then
  G=$'\e[32m'; R=$'\e[31m'; Y=$'\e[33m'; B=$'\e[1m'; D=$'\e[2m'; N=$'\e[0m'
else
  G=; R=; Y=; B=; D=; N=
fi

n_ok=0
n_miss=0
missing=()

hdr() { [ "$QUIET" -eq 1 ] && return 0; printf '\n%s%s%s\n' "$B" "$1" "$N"; }

# Best-effort version string. Probes with stdin closed and a hard timeout so a
# tool that ignores the flag and waits for input cannot hang the report.
ver() {
  [ "$VERSIONS" -eq 1 ] || return 0
  local c="$1" out=
  for f in -version --version -V version; do
    out=$(timeout 5 "$c" "$f" </dev/null 2>&1 \
          | grep -oEm1 '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    [ -n "$out" ] && break
  done
  [ -n "$out" ] && printf ' %s(%s)%s' "$D" "$out" "$N"
}

# chk <command> [how to install it]
chk() {
  local cmd="$1" hint="${2:-}" path
  if path=$(command -v "$cmd" 2>/dev/null); then
    n_ok=$((n_ok + 1))
    [ "$QUIET" -eq 1 ] || printf '  %sok  %s %-20s %s%s%s%s\n' \
      "$G" "$N" "$cmd" "$D" "$path" "$N" "$(ver "$cmd")"
  else
    n_miss=$((n_miss + 1))
    missing+=("$cmd")
    printf '  %sMISS%s %-20s %s%s%s\n' "$R" "$N" "$cmd" "$D" "$hint" "$N"
  fi
}

# chkfile <path> <label> [hint] — reports line count for wordlists
chkfile() {
  local p="${1/#\~/$HOME}" label="$2" hint="${3:-}"
  if [ -e "$p" ]; then
    n_ok=$((n_ok + 1))
    local extra=""
    if [ -f "$p" ]; then
      extra=$(printf ' %s(%s lines)%s' "$D" "$(wc -l < "$p" | tr -d ' ')" "$N")
    elif [ -d "$p" ]; then
      extra=$(printf ' %s(%s entries)%s' "$D" "$(find "$p" -maxdepth 1 | wc -l | tr -d ' ')" "$N")
    fi
    [ "$QUIET" -eq 1 ] || printf '  %sok  %s %-20s %s%s%s%s\n' \
      "$G" "$N" "$label" "$D" "$p" "$N" "$extra"
  else
    n_miss=$((n_miss + 1))
    missing+=("$label")
    printf '  %sMISS%s %-20s %s%s%s\n' "$R" "$N" "$label" "$D" "${hint:-$p}" "$N"
  fi
}

printf '%sDeep Recon Runbook — dependency check%s\n' "$B" "$N"
printf '%shost: %s · %s%s\n' "$D" "$(hostname)" "$(date '+%Y-%m-%d %H:%M')" "$N"

hdr 'Core runtimes'
chk go      'apt install golang-go'
chk python3 'apt install python3'
chk pipx    'apt install pipx   # do NOT use bare pip on Kali (PEP 668)'
chk git     'apt install git'
chk curl    'apt install curl'
chk wget    'apt install wget'
chk jq      'apt install jq'
chk nmap    'apt install nmap'
chk massdns 'apt install massdns   # hard dependency of puredns'

hdr 'ProjectDiscovery suite (pdtm -install-all)'
chk pdtm              'go install github.com/projectdiscovery/pdtm/cmd/pdtm@latest'
chk subfinder         'pdtm -install subfinder'
chk httpx             'pdtm -install httpx'
chk dnsx              'pdtm -install dnsx'
chk naabu             'pdtm -install naabu'
chk katana            'pdtm -install katana'
chk nuclei            'pdtm -install nuclei'
chk notify            'pdtm -install notify'
chk tlsx              'pdtm -install tlsx'
chk alterx            'pdtm -install alterx'
chk cdncheck          'pdtm -install cdncheck'
chk asnmap            'pdtm -install asnmap'
chk interactsh-client 'pdtm -install interactsh-client'

hdr 'Go tools'
chk anew               'go install github.com/tomnomnom/anew@latest'
chk unfurl             'go install github.com/tomnomnom/unfurl@latest'
chk gau                'go install github.com/lc/gau/v2/cmd/gau@latest'
chk ffuf               'go install github.com/ffuf/ffuf/v2@latest'
chk puredns            'go install github.com/d3mondev/puredns/v2@latest'
chk gowitness          'go install github.com/sensepost/gowitness@latest'
chk amass              'go install github.com/owasp-amass/amass/v4/...@master'
chk subzy              'go install github.com/PentestPad/subzy@latest'
chk jsluice            'go install github.com/BishopFox/jsluice/cmd/jsluice@latest'
chk sourcemapper       'go install github.com/denandz/sourcemapper@latest'
chk github-subdomains  'go install github.com/gwen001/github-subdomains@latest'
chk trufflehog         'curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin'

hdr 'Python tools (pipx)'
chk arjun        'pipx install arjun'
chk xnLinkFinder 'pipx install xnLinkFinder'
chk dnsvalidator 'pipx install dnsvalidator'
chk shodan       'pipx install shodan'

hdr 'Wordlists & resolvers'
chkfile ~/wordlists/SecLists                   'SecLists'       'git clone --depth 1 https://github.com/danielmiessler/SecLists ~/wordlists/SecLists'
chkfile ~/wordlists/best-dns-wordlist.txt      'best-dns-list'  'wget -O ~/wordlists/best-dns-wordlist.txt https://wordlists-cdn.assetnote.io/data/manual/best-dns-wordlist.txt'
chkfile ~/wordlists/httparchive_directories.txt 'httparchive-dirs' 'see kali-setup.sh wordlists'
chkfile ~/resolvers.txt                         'resolvers.txt'  'dnsvalidator -tL https://public-dns.info/nameservers.txt -threads 100 -o ~/resolvers.txt'

hdr 'Nuclei templates'
# nuclei picks its own templates dir and it has moved between versions, so
# resolve it rather than assuming. The runbook hardcodes ~/nuclei-templates.
tpl_real=""
for cand in "$HOME/.local/nuclei-templates" "$HOME/nuclei-templates"; do
  [ -d "$cand" ] && { tpl_real="$cand"; break; }
done
if [ -n "$tpl_real" ]; then
  n_ok=$((n_ok + 1))
  [ "$QUIET" -eq 1 ] || printf '  %sok  %s %-20s %s%s%s\n' "$G" "$N" 'templates' "$D" "$tpl_real" "$N"
  if [ ! -e "$HOME/nuclei-templates" ]; then
    printf '  %sWARN%s %-20s %sruntime dir is %s but the runbook uses ~/nuclei-templates — symlink it%s\n' \
      "$Y" "$N" 'templates path' "$D" "$tpl_real" "$N"
  fi
else
  n_miss=$((n_miss + 1)); missing+=('nuclei-templates')
  printf '  %sMISS%s %-20s %snuclei -update-templates%s\n' "$R" "$N" 'templates' "$D" "$N"
fi

hdr 'API keys / provider configs'
chkfile ~/.config/subfinder/provider-config.yaml 'subfinder keys' 'passive enum misses most subdomains without these'
chkfile ~/.config/amass/config.ini               'amass config'   'populate with the same provider keys'
for v in GITHUB_TOKEN SHODAN_API_KEY; do
  if [ -n "${!v:-}" ]; then
    [ "$QUIET" -eq 1 ] || printf '  %sok  %s %-20s %s<set>%s\n' "$G" "$N" "\$$v" "$D" "$N"
  else
    printf '  %sWARN%s %-20s %snot exported (github-subdomains / shodan need it)%s\n' "$Y" "$N" "\$$v" "$D" "$N"
  fi
done

printf '\n%s%s%s\n' "$B" '────────────────────────────────' "$N"
printf '%spresent: %d%s   ' "$G" "$n_ok" "$N"
if [ "$n_miss" -eq 0 ]; then
  printf '%smissing: 0%s\n\nAll runbook dependencies satisfied.\n' "$G" "$N"
  exit 0
fi
printf '%smissing: %d%s\n\n%s\n\nRun ./kali-setup.sh to install the missing pieces.\n' \
  "$R" "$n_miss" "$N" "$(printf '%s ' "${missing[@]}")"
exit 1
