# Deep Recon Runbook

Reusable per-target recon pipeline for bug bounty. Each phase feeds the next.

**Before anything:** confirm the target is in scope for a program you're authorized on. Respect rate limits and out-of-scope lists. Aggressive brute forcing against a program that forbids it gets you banned, not paid.

---

## Setup (once per machine)

```bash
# ProjectDiscovery tool manager - installs subfinder, httpx, dnsx, naabu, katana, nuclei, notify, tlsx, alterx, cdncheck
go install -v github.com/projectdiscovery/pdtm/cmd/pdtm@latest
pdtm -install-all

# Core extras
go install github.com/tomnomnom/anew@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/ffuf/ffuf/v2@latest
go install github.com/d3mondev/puredns/v2@latest
go install github.com/sensepost/gowitness@latest
go install github.com/owasp-amass/amass/v4/...@master
pipx install arjun
pipx install trufflehog   # or: brew install trufflehog

# Wordlists
git clone https://github.com/danielmiessler/SecLists ~/wordlists/SecLists
wget -O ~/wordlists/best-dns-wordlist.txt https://wordlists-cdn.assetnote.io/data/manual/best-dns-wordlist.txt
wget -O ~/wordlists/httparchive_directories.txt https://wordlists-cdn.assetnote.io/data/automated/httparchive_directories_1m_2024_05_28.txt
```

### API keys — do not skip this
Passive enumeration without keys misses a large share of subdomains. Populate:

```bash
# ~/.config/subfinder/provider-config.yaml
# ~/.config/amass/config.ini
```

Free-tier keys worth getting: SecurityTrails, Shodan, Censys, VirusTotal, Chaos, GitHub (PAT), BinaryEdge, Netlas, ZoomEye, Intelx, BuiltWith, FullHunt.

### Clean resolvers (required for mass DNS)
```bash
pip install dnsvalidator
dnsvalidator -tL https://public-dns.info/nameservers.txt -threads 100 -o ~/resolvers.txt
# Refresh weekly. Stale resolvers = false positives = wasted hours.
```

---

## Phase 0 — Target workspace

```bash
export TARGET="example.com"
export WORK=~/recon/$TARGET/$(date +%Y-%m-%d)
mkdir -p $WORK/{roots,subs,live,ports,urls,js,params,screens,nuclei,notes}
cd $WORK
```

Write `notes/scope.md` by hand before you scan:
- Wildcard scope vs. explicit host list
- Explicit out-of-scope (respect it — this is what gets reports rejected)
- Acquisitions / subsidiaries in scope?
- Rate limit rules, required UA header, VDP vs. paid
- Payout table — tells you which bug classes to prioritize

---

## Phase 1 — Horizontal enum (find all the roots)

Goal: every apex domain the org owns, not just the one in the brief.

```bash
# ASN -> CIDR
asnmap -d $TARGET -silent | anew roots/cidrs.txt
asnmap -org "Example Inc" -silent | anew roots/cidrs.txt

# Reverse-scrape TLS certs off owned IP ranges -> reveals unlisted domains
cat roots/cidrs.txt | tlsx -san -cn -silent -resp-only | anew roots/cert-domains.txt

# Amass intel: reverse whois + org correlation
amass intel -d $TARGET -whois -o roots/amass-intel.txt
amass intel -asn <ASN> -o roots/amass-asn.txt

# Favicon pivot (Shodan) - finds sibling infra sharing the same favicon
# curl the favicon, base64, mmh3 hash, then:
shodan search "http.favicon.hash:<HASH>" --fields ip_str,port,hostnames
```

Also do manually: Crunchbase/Wikipedia/SEC filings for acquisitions, shared Google Analytics IDs (`builtwith.com/relationships/`), copyright strings.

Consolidate to `roots/roots.txt` — one apex per line. **Only include what's in scope.**

---

## Phase 2 — Vertical enum (subdomains per root)

```bash
# Passive
subfinder -dL roots/roots.txt -all -silent -o subs/subfinder.txt
amass enum -passive -df roots/roots.txt -o subs/amass.txt
cat roots/roots.txt | while read d; do curl -s "https://crt.name/v1/search?apex=target.com" \
  | jq -r '.[].name_value' | sed 's/\*\.//g'; done | anew subs/crtsh.txt
github-subdomains -d $TARGET -t $GITHUB_TOKEN -o subs/github.txt

cat subs/*.txt | sort -u | anew subs/passive.txt

# Active brute
puredns bruteforce ~/wordlists/best-dns-wordlist.txt -d $TARGET \
  -r ~/resolvers.txt --write subs/brute.txt

# Permutations from what you already found (catches admin-dev, staging2, api-v3)
alterx -l subs/passive.txt -silent | puredns resolve -r ~/resolvers.txt --write subs/perms.txt

cat subs/passive.txt subs/brute.txt subs/perms.txt | sort -u > subs/all.txt
wc -l subs/all.txt
```

**Recursion:** re-run permutation + brute against interesting branches (e.g. anything matching `dev|stage|uat|internal|admin`). Deep branches are where forgotten apps live.

---

## Phase 3 — Resolve, probe, takeover check

```bash
# Resolve + capture CNAMEs
dnsx -l subs/all.txt -a -cname -resp -silent -o live/dns.txt
dnsx -l subs/all.txt -silent -o live/resolved.txt

# Live HTTP probe with fingerprint data
httpx -l live/resolved.txt \
  -status-code -title -tech-detect -content-length -web-server -cdn -location \
  -follow-redirects -threads 50 -o live/httpx.txt

httpx -l live/resolved.txt -silent -json -o live/httpx.json

# Subdomain takeover
subzy run --targets subs/all.txt --hide_fails
nuclei -l live/resolved.txt -t ~/nuclei-templates/http/takeovers/ -o nuclei/takeover.txt
```

Grep `live/dns.txt` for CNAMEs pointing at third-party services (`*.s3.amazonaws.com`, `*.github.io`, `*.azurewebsites.net`, `*.herokudns.com`) with NXDOMAIN — that's a takeover candidate.

---

## Phase 4 — Triage (stop and think here)

This phase is the difference between deep recon and a pile of text files.

```bash
# Screenshot everything, then eyeball the grid
gowitness scan file -f live/resolved.txt --write-db --screenshot-path screens/
# gowitness report server   # browse at localhost:7171

# Group by title to collapse duplicate marketing pages
cat live/httpx.json | jq -r '.title' | sort | uniq -c | sort -rn | head -50

# Flag the interesting ones
grep -Ei "admin|dev|stage|uat|test|internal|api|jenkins|grafana|kibana|jira|vpn|portal|legacy|old" \
  live/httpx.txt > notes/priority.txt

# Non-200s are often more interesting than 200s
grep -E " \[(401|403|500|503)\] " live/httpx.txt > notes/interesting-status.txt
```

Build `notes/priority.txt` by hand from the screenshots. Your time goes to the weird 5%.

---

## Phase 5 — Ports & services

```bash
naabu -l live/resolved.txt -top-ports 1000 -rate 1000 -silent -o ports/naabu.txt

# Service/version detect on what's open
naabu -l live/resolved.txt -top-ports 1000 -silent \
  | tee ports/naabu.txt \
  | cut -d: -f1 | sort -u | nmap -sV -sC -iL - -oA ports/nmap-detail

# Probe non-standard web ports
httpx -l ports/naabu.txt -status-code -title -tech-detect -o ports/web-alt-ports.txt
```

Non-web services on odd ports (Redis, Elasticsearch, RabbitMQ, MongoDB, exposed dashboards) are a frequent source of high-severity findings.

---

## Phase 6 — URLs & content discovery

```bash
# Historical URLs
cat live/resolved.txt | gau --threads 10 --subs | anew urls/gau.txt

# Crawl (handles JS-rendered routes)
katana -list live/resolved.txt -jc -kf all -d 3 -silent -o urls/katana.txt

cat urls/gau.txt urls/katana.txt | sort -u > urls/all.txt

# Filter out noise
cat urls/all.txt | grep -vE "\.(png|jpg|jpeg|gif|svg|woff2?|ttf|ico|css)(\?|$)" > urls/clean.txt

# Which historical URLs are still alive?
cat urls/clean.txt | httpx -silent -mc 200,201,204,301,302,307,401,403,405,500 -o urls/live-urls.txt

# Directory brute on priority hosts
ffuf -w ~/wordlists/httparchive_directories.txt \
  -u https://TARGET_HOST/FUZZ \
  -mc all -fc 404 -ac -t 40 -o urls/ffuf-TARGET_HOST.json

# Virtual host discovery (finds apps not exposed via DNS)
ffuf -w subs/all.txt -u https://TARGET_IP -H "Host: FUZZ" -ac -t 40
```

`-ac` (auto-calibrate) is essential — without it soft-404s drown you.

---

## Phase 7 — JS analysis (highest return per hour)

```bash
# Collect JS
cat urls/all.txt | grep -Ei "\.js(\?|$)" | sort -u > js/js-urls.txt
katana -list live/resolved.txt -jc -silent | grep "\.js" | anew js/js-urls.txt

mkdir -p js/files
cat js/js-urls.txt | while read u; do
  curl -sL --max-time 15 "$u" -o "js/files/$(echo $u | md5sum | cut -d' ' -f1).js"
done

# Extract endpoints + secrets
jsluice urls js/files/*.js | jq -r '.url' | anew js/endpoints.txt
jsluice secrets js/files/*.js | anew js/secrets.txt

xnLinkFinder -i js/js-urls.txt -o js/xnlinkfinder.txt
trufflehog filesystem js/files/ --results=verified,unknown --json > js/trufflehog.json

# Exposed sourcemaps = original source code
cat js/js-urls.txt | sed 's/$/.map/' | httpx -silent -mc 200 -o js/sourcemaps.txt
# then: sourcemapper -url <map-url> -output js/src/
```

What to look for: internal API routes, hardcoded keys, feature flags, role/permission strings, admin-only endpoints referenced but not linked, old API versions (`/api/v1/` when prod uses v3).

---

## Phase 8 — Parameters

```bash
# Mine param names from what you've collected
cat urls/all.txt | unfurl -u keys | sort -u > params/known-params.txt

# Hidden param discovery on priority endpoints
arjun -i notes/priority.txt -oT params/arjun.txt -t 10

# URLs that already carry params - your injection testing surface
cat urls/clean.txt | grep "=" | sort -u > params/urls-with-params.txt
```

This is the bridge from recon to actual testing. IDOR, SSRF, injection hunting all start from this list.

---

## Phase 9 — Automated sweep

```bash
nuclei -l live/resolved.txt \
  -t ~/nuclei-templates/ \
  -severity low,medium,high,critical \
  -rl 50 -c 25 \
  -o nuclei/results.txt

# Blind/OOB
interactsh-client -v   # get a payload domain, feed into nuclei -iserver or manual tests
```

Treat nuclei output as leads, not findings. **Manually verify every hit before reporting** — false positives on a program tank your reputation score.

---

## Phase 10 — Correlate

Build one dataset. This is what makes recon compound.

```bash
# Quick CSV from httpx JSON
cat live/httpx.json | jq -r '[.url, .status_code, .title, (.tech|join("|")), .webserver] | @csv' \
  > notes/attack-surface.csv
```

Keep `notes/findings.md` with per-host observations. The bounty is usually in a correlation you'd otherwise forget — "staging accepts the same JWT as prod," "this old API version skips the auth middleware."

---

## Phase 11 — Continuous monitoring

Programs change constantly. Being first to a new asset is a reliable bounty source.

```bash
#!/bin/bash
# ~/bin/monitor.sh  — cron: 0 6 * * *
TARGET="example.com"
STORE=~/recon/$TARGET/monitor
mkdir -p $STORE

subfinder -d $TARGET -all -silent \
  | dnsx -silent \
  | anew $STORE/known-subs.txt \
  > $STORE/new-today.txt

if [ -s $STORE/new-today.txt ]; then
  httpx -l $STORE/new-today.txt -status-code -title -tech-detect -silent \
    | notify -provider discord
fi
```

Diff on subdomains, and separately on `httpx` response hashes (a changed hash on a known host means the app was redeployed — new code, new bugs).

---

## Quick reference — the pipeline in one block

```bash
subfinder -dL roots/roots.txt -all -silent \
  | anew subs/all.txt \
  | dnsx -silent \
  | httpx -silent -status-code -title -tech-detect \
  | tee live/httpx.txt \
  | grep -Ei "admin|dev|stage|api|internal" \
  | tee notes/priority.txt
```

---

## Habits that separate people who get paid

1. **Never report unverified automated output.** Reproduce manually, write clear steps, show impact.
2. **Go where automation doesn't.** Everyone runs nuclei on the main domain. Almost nobody reads the JS of a 2019 staging app.
3. **Business logic beats scanners.** Recon finds the surface; understanding the app's auth/roles/workflows finds the money bugs.
4. **Re-recon old targets.** Your six-month-old notes plus today's diff is an advantage new hunters don't have.
5. **Respect scope and rate limits.** One out-of-scope test can end your access to a program permanently.
