#!/usr/bin/env bash
#
# kali-setup.sh — install everything the Deep Recon Runbook calls, on Kali.
#
# Idempotent: already-installed tools are skipped. Safe to re-run to top up.
#
# Usage:
#   ./kali-setup.sh                      everything
#   ./kali-setup.sh gotools python       only those sections
#   ./kali-setup.sh --force gotools      reinstall even if present
#   ./kali-setup.sh --list               show section names
#
# Sections: deps pdtm gotools python trufflehog wordlists resolvers templates
#
# Notes:
#   - Uses pipx, never bare pip: Kali marks its system Python EXTERNALLY-MANAGED
#     (PEP 668), so `pip install` fails there.
#   - Wordlists are ~2.5 GB. Skip with: ./kali-setup.sh deps pdtm gotools python

set -uo pipefail

FORCE=0
SECTIONS=()
ALL=(deps pdtm gotools python trufflehog wordlists resolvers templates)

for a in "$@"; do
  case "$a" in
    --force)   FORCE=1 ;;
    --list)    printf '%s\n' "${ALL[@]}"; exit 0 ;;
    -h|--help) sed -n '3,19p' "$0" | sed 's/^# \?//'; exit 0 ;;
    -*)        echo "unknown option: $a" >&2; exit 2 ;;
    *)         SECTIONS+=("$a") ;;
  esac
done

# Reject unknown section names rather than silently doing nothing.
for s in ${SECTIONS[@]+"${SECTIONS[@]}"}; do
  case " ${ALL[*]} " in
    *" $s "*) ;;
    *) printf 'unknown section: %s\nvalid sections: %s\n' "$s" "${ALL[*]}" >&2; exit 2 ;;
  esac
done
[ ${#SECTIONS[@]} -eq 0 ] && SECTIONS=("${ALL[@]}")

if [ -t 1 ]; then
  G=$'\e[32m'; R=$'\e[31m'; Y=$'\e[33m'; B=$'\e[1m'; D=$'\e[2m'; N=$'\e[0m'
else
  G=; R=; Y=; B=; D=; N=
fi

log()  { printf '%s==>%s %s\n' "$B" "$N" "$*"; }
ok()   { printf '  %sok%s   %s\n' "$G" "$N" "$*"; }
skip() { printf '  %sskip%s %s %s(already present)%s\n' "$D" "$N" "$*" "$D" "$N"; }
warn() { printf '  %swarn%s %s\n' "$Y" "$N" "$*"; }
fail() { printf '  %sFAIL%s %s\n' "$R" "$N" "$*"; FAILED+=("$1"); }

FAILED=()
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

wants() { local s; for s in "${SECTIONS[@]}"; do [ "$s" = "$1" ] && return 0; done; return 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

# Make Go-installed binaries visible to the rest of this script.
if have go; then
  GOBIN="$(go env GOPATH 2>/dev/null)/bin"
  export PATH="$PATH:$GOBIN"
else
  GOBIN="$HOME/go/bin"
fi

# goget <binary> <module path>
goget() {
  local bin="$1" mod="$2"
  if have "$bin" && [ "$FORCE" -eq 0 ]; then skip "$bin"; return 0; fi
  if go install -v "$mod" >/dev/null 2>&1; then ok "$bin"; else fail "$bin"; fi
}

# pipxget <binary> <package>
pipxget() {
  local bin="$1" pkg="$2"
  if have "$bin" && [ "$FORCE" -eq 0 ]; then skip "$bin"; return 0; fi
  if pipx install "$pkg" >/dev/null 2>&1 \
     || pipx install --force "$pkg" >/dev/null 2>&1; then ok "$bin"; else fail "$bin"; fi
}

# ───────────────────────────────────────────── deps
if wants deps; then
  log 'System packages'
  $SUDO apt-get update -qq 2>/dev/null || warn 'apt-get update failed; continuing'
  # massdns is a hard dependency of puredns. libldns-dev is for building it
  # from source if the package is unavailable.
  pkgs=(golang-go git curl wget jq nmap pipx massdns libldns-dev build-essential)
  for p in "${pkgs[@]}"; do
    if dpkg -s "$p" >/dev/null 2>&1; then
      skip "$p"
    elif $SUDO apt-get install -y -qq "$p" >/dev/null 2>&1; then
      ok "$p"
    else
      fail "$p"
    fi
  done

  # massdns fallback: build from source if apt did not provide it.
  if ! have massdns; then
    warn 'massdns not in PATH — building from source (puredns needs it)'
    tmp=$(mktemp -d)
    if git clone --depth 1 -q https://github.com/blechschmidt/massdns "$tmp/massdns" \
       && make -C "$tmp/massdns" -s >/dev/null 2>&1 \
       && $SUDO install -m 0755 "$tmp/massdns/bin/massdns" /usr/local/bin/massdns; then
      ok 'massdns (from source)'
    else
      fail 'massdns'
    fi
    rm -rf "$tmp"
  fi

  pipx ensurepath >/dev/null 2>&1 || true

  # Persist ~/go/bin on PATH so a new shell finds the Go tools.
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$rc" ] || continue
    if ! grep -q 'go env GOPATH' "$rc" 2>/dev/null && ! grep -q '/go/bin' "$rc" 2>/dev/null; then
      printf '\n# added by kali-setup.sh\nexport PATH="$PATH:$(go env GOPATH)/bin"\n' >> "$rc"
      ok "PATH appended to $rc"
    else
      skip "PATH in $(basename "$rc")"
    fi
  done
fi

if ! have go; then
  printf '\n%sgo is not installed — cannot continue. Run: %s apt install golang-go%s\n' "$R" "$SUDO" "$N"
  exit 1
fi
export PATH="$PATH:$(go env GOPATH)/bin"

# ───────────────────────────────────────────── pdtm
if wants pdtm; then
  log 'ProjectDiscovery suite (via pdtm)'
  goget pdtm github.com/projectdiscovery/pdtm/cmd/pdtm@latest
  if have pdtm; then
    # pdtm installs into ~/.pdtm/go/bin; make sure that is on PATH too.
    export PATH="$PATH:$HOME/.pdtm/go/bin"
    if pdtm -install-all -silent >/dev/null 2>&1 || pdtm -install-all >/dev/null 2>&1; then
      ok 'pdtm -install-all'
    else
      warn 'pdtm -install-all reported errors; falling back to direct installs'
    fi
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      [ -f "$rc" ] || continue
      grep -q '.pdtm/go/bin' "$rc" 2>/dev/null || \
        printf 'export PATH="$PATH:$HOME/.pdtm/go/bin"\n' >> "$rc"
    done
  fi
  # Direct installs as a safety net — pdtm occasionally skips tools.
  goget subfinder         github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
  goget httpx             github.com/projectdiscovery/httpx/cmd/httpx@latest
  goget dnsx              github.com/projectdiscovery/dnsx/cmd/dnsx@latest
  goget naabu             github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
  goget katana            github.com/projectdiscovery/katana/cmd/katana@latest
  goget nuclei            github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
  goget notify            github.com/projectdiscovery/notify/cmd/notify@latest
  goget tlsx              github.com/projectdiscovery/tlsx/cmd/tlsx@latest
  goget alterx            github.com/projectdiscovery/alterx/cmd/alterx@latest
  goget cdncheck          github.com/projectdiscovery/cdncheck/cmd/cdncheck@latest
  goget asnmap            github.com/projectdiscovery/asnmap/cmd/asnmap@latest
  goget interactsh-client github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest
fi

# ───────────────────────────────────────────── gotools
if wants gotools; then
  log 'Go tools'
  goget anew              github.com/tomnomnom/anew@latest
  goget unfurl            github.com/tomnomnom/unfurl@latest
  goget gau               github.com/lc/gau/v2/cmd/gau@latest
  goget ffuf              github.com/ffuf/ffuf/v2@latest
  goget puredns           github.com/d3mondev/puredns/v2@latest
  goget gowitness         github.com/sensepost/gowitness@latest
  goget subzy             github.com/PentestPad/subzy@latest
  goget jsluice           github.com/BishopFox/jsluice/cmd/jsluice@latest
  goget sourcemapper      github.com/denandz/sourcemapper@latest
  goget github-subdomains github.com/gwen001/github-subdomains@latest
  # amass v4 is a multi-binary module, hence the /... pattern.
  if have amass && [ "$FORCE" -eq 0 ]; then
    skip amass
  elif go install -v github.com/owasp-amass/amass/v4/...@master >/dev/null 2>&1; then
    ok amass
  else
    fail amass
  fi
fi

# ───────────────────────────────────────────── python
if wants python; then
  log 'Python tools (pipx)'
  if ! have pipx; then
    fail 'pipx missing — run the deps section first'
  else
    pipxget arjun        arjun
    pipxget xnLinkFinder xnLinkFinder
    pipxget dnsvalidator dnsvalidator
    pipxget shodan       shodan
  fi
fi

# ───────────────────────────────────────────── trufflehog
if wants trufflehog; then
  log 'trufflehog'
  # NOT pipx: the PyPI "trufflehog" package is the abandoned v2 and does not
  # support the --results flag the runbook uses. v3 is a Go rewrite.
  if have trufflehog && [ "$FORCE" -eq 0 ]; then
    skip trufflehog
  elif curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh \
       | $SUDO sh -s -- -b /usr/local/bin >/dev/null 2>&1; then
    ok 'trufflehog (v3)'
  elif go install github.com/trufflesecurity/trufflehog/v3@latest >/dev/null 2>&1; then
    ok 'trufflehog (v3, go install)'
  else
    fail trufflehog
  fi
fi

# ───────────────────────────────────────────── wordlists
if wants wordlists; then
  log 'Wordlists (~2.5 GB)'
  mkdir -p "$HOME/wordlists"
  if [ -d "$HOME/wordlists/SecLists" ] && [ "$FORCE" -eq 0 ]; then
    skip SecLists
  elif git clone --depth 1 -q https://github.com/danielmiessler/SecLists "$HOME/wordlists/SecLists"; then
    ok SecLists
  else
    fail SecLists
  fi

  dl() {
    local out="$HOME/wordlists/$1" url="$2"
    if [ -s "$out" ] && [ "$FORCE" -eq 0 ]; then skip "$1"; return 0; fi
    if wget -q -O "$out" "$url" && [ -s "$out" ]; then
      ok "$1 ($(wc -l < "$out" | tr -d ' ') lines)"
    else
      rm -f "$out"; fail "$1"
    fi
  }
  dl best-dns-wordlist.txt \
     https://wordlists-cdn.assetnote.io/data/manual/best-dns-wordlist.txt
  dl httparchive_directories.txt \
     https://wordlists-cdn.assetnote.io/data/automated/httparchive_directories_1m_2024_05_28.txt
fi

# ───────────────────────────────────────────── resolvers
if wants resolvers; then
  log 'Clean DNS resolvers'
  if [ -s "$HOME/resolvers.txt" ] && [ "$FORCE" -eq 0 ]; then
    skip 'resolvers.txt'
  elif wget -q -O "$HOME/resolvers.txt" \
       https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt \
       && [ -s "$HOME/resolvers.txt" ]; then
    ok "resolvers.txt ($(wc -l < "$HOME/resolvers.txt" | tr -d ' ') resolvers, trickest list)"
    warn 'for a self-validated list: dnsvalidator -tL https://public-dns.info/nameservers.txt -threads 100 -o ~/resolvers.txt  (slow)'
  else
    fail 'resolvers.txt'
  fi
fi

# ───────────────────────────────────────────── templates
if wants templates; then
  log 'Nuclei templates'
  if have nuclei; then
    nuclei -update-templates -silent >/dev/null 2>&1 || nuclei -update-templates >/dev/null 2>&1 || true
    # nuclei's default templates dir has moved between versions; the runbook
    # hardcodes ~/nuclei-templates, so point that at wherever they really are.
    real=""
    for cand in "$HOME/.local/nuclei-templates" "$HOME/nuclei-templates"; do
      [ -d "$cand" ] && { real="$cand"; break; }
    done
    if [ -z "$real" ]; then
      fail 'nuclei-templates (not found after update)'
    elif [ "$real" = "$HOME/nuclei-templates" ]; then
      ok "templates at $real"
    elif [ -e "$HOME/nuclei-templates" ]; then
      ok "templates at $real (~/nuclei-templates already exists)"
    elif ln -s "$real" "$HOME/nuclei-templates"; then
      ok "templates at $real, symlinked to ~/nuclei-templates for runbook paths"
    else
      warn "templates at $real but could not symlink ~/nuclei-templates"
    fi
  else
    fail 'nuclei not installed — run the pdtm section first'
  fi
fi

# ───────────────────────────────────────────── summary
printf '\n%s────────────────────────────────%s\n' "$B" "$N"
if [ ${#FAILED[@]} -eq 0 ]; then
  printf '%sAll requested sections completed.%s\n' "$G" "$N"
else
  printf '%s%d item(s) failed:%s %s\n' "$R" "${#FAILED[@]}" "$N" "$(printf '%s ' "${FAILED[@]}")"
fi
cat <<'EOF'

Next steps:
  1. exec $SHELL -l                 reload PATH
  2. ./kali-check.sh --versions     verify
  3. Add API keys — passive enum is badly degraded without them:
       ~/.config/subfinder/provider-config.yaml
       ~/.config/amass/config.ini
     Worth getting (free tiers): SecurityTrails, Shodan, Censys, VirusTotal,
     Chaos, GitHub PAT, BinaryEdge, Netlas, ZoomEye, Intelx, BuiltWith, FullHunt
  4. export GITHUB_TOKEN=...        needed by github-subdomains
EOF
[ ${#FAILED[@]} -eq 0 ] || exit 1
