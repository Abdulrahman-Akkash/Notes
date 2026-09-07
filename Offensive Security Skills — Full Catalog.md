# Offensive Security Skills — Full Catalog

**Machine:** kali · **Skills directory:** `~/.claude/skills/`
**Installed:** 147 skills · 2.72 MB · ~360,000 words
**Generated:** 2026-09-07

---

## 1. Read this first: "load all of them" is not possible

The full corpus is **~360K words ≈ 700K–900K tokens**. That exceeds a single context window, so there is no state in which all 147 are resident at once. It also would not help if it were possible — a context stuffed with 147 playbooks makes the model *worse* at picking the right one, not better.

**How skills actually work:** they are lazy-loaded. Only the `name` + `description` of each skill sits in context permanently (that is the list you see). The full body is pulled in on demand — either automatically when the description matches what you are doing, or explicitly when you type `/skill-name`. So they are already "available" without being loaded.

**What to do instead:** load a *working set* of 3–6 skills for the mission at hand. Section 2 gives pre-built sets. Everything else stays one keystroke away.

| | |
|---|---|
| Invoke manually | `/hunt-idor` |
| Ask the model to load a set | "load hunt-idor, hunt-graphql and triage-validation" |
| Largest single skill | `osint-methodology` (93 KB) |
| Smallest | `email-security` (3 KB) |

---

## 2. Working sets (load these, not everything)

### Starter kit — covers ~80% of web bounty work
```
bug-bounty · hunt-idor · hunt-business-logic · triage-validation · report-writing
```
Find → validate → write. If you only ever memorise one line of this document, this is it.

### Session opener
`bb-methodology` (where am I, what next) or `redteam-mindset` (engagement discipline) → then `recon-playbook`.

### Mission-specific sets

| Mission | Load |
|---|---|
| New target, cold start | `bb-methodology`, `recon-playbook`, `subdomain-enumeration`, `hunt-source-leak` |
| REST/API BOLA hunt | `hunt-idor`, `hunt-broken-function-level-auth`, `hunt-mass-assignment`, `hunt-api-misconfig`, `hunt-schema-enumeration` |
| GraphQL target | `hunt-graphql`, `hunt-idor`, `hunt-api-misconfig` |
| Auth / ATO chain | `hunt-ato`, `hunt-auth-bypass`, `hunt-oauth`, `hunt-mfa-bypass`, `hunt-session` |
| Cloud / serverless | `hunt-cloud-misconfig`, `cloud-iam-deep`, `js-secrets-extraction`, `hunt-firebase` |
| WordPress | `hunt-wordpress`, `wordpress-cors-xmlrpc-rce-chain`, `wp-plugin-cve-hunt` |
| Enterprise perimeter | `enterprise-vpn-attack`, `hunt-ntlm-info`, `password-spray-methodology`, `m365-entra-attack` |
| Writing it up | `triage-validation` → `evidence-hygiene` → `report-writing` (+ `bugcrowd-reporting` if Bugcrowd) |

---

## 3. Six skills are installed but the model cannot auto-invoke them

These carry `disable-model-invocation: true` in their frontmatter. They will never be selected automatically — **you must type the slash command yourself**, or ask for them by name.

| Skill | Size | What it does |
|---|---|---|
| `cross-attack-chains` | 26 KB | Chain multiple vulns into critical-impact attack paths |
| `wordpress-full-compromise` | 25 KB | Optimal kill chains for full WP compromise |
| `attack-patterns-reference` | 15 KB | Catalog of 25 attacks / 18 WP / 8 CORS patterns to match findings against |
| `pentest-playbook` | 8 KB | 7-phase pipeline, passive recon → exploitation |
| `docker-privesc` | 7 KB | Container escape to host root, 5 techniques |
| `google-dorks-catalog` | 4 KB | High-precision dorks for exposed configs, secrets, credentials |

This is worth fixing — `cross-attack-chains` and `google-dorks-catalog` in particular are ones you'd want pulled in automatically. To enable auto-invocation:

```bash
sed -i '/^disable-model-invocation: true$/d' ~/.claude/skills/{cross-attack-chains,wordpress-full-compromise,attack-patterns-reference,pentest-playbook,docker-privesc,google-dorks-catalog}/SKILL.md
```

---

## 4. Full catalog — all 147

Sizes are the `SKILL.md` body. 🔒 marks a skill from section 3 (manual invocation only).

### 4.1 Orchestrators, methodology & meta — 18

| Skill | Size | Purpose |
|---|---|---|
| `bug-bounty` | 78 KB | Master orchestrator: recon → hunt (30+ classes) → chain → AI testing → report |
| `bb-local-toolkit` | 76 KB | Full local BB workflow incl. source audit, H1 scope, bypass tables |
| `osint-methodology` | 93 KB | 5-stage recon pipeline, asset-graph discipline, identity-fabric mapping |
| `parallel-recon-triad` | 33 KB | Overlapping multi-phase recon agent waves for batch engagements |
| `recon-playbook` | 32 KB | 4-phase pipeline tuned for max findings per minute across batches |
| `bb-methodology` | 32 KB | 5-phase non-linear workflow + critical-thinking framework; "what next" router |
| `security-arsenal` | 29 KB | Payloads, bypass tables, wordlists, gf patterns, always-rejected list |
| `redteam-mindset` | 26 KB | Operator discipline; the corrections separating red team from defensive WAPT |
| `cross-attack-chains` 🔒 | 26 KB | Chain vulns into critical attack paths |
| `recon-sector-expansion` | 18 KB | Pick which sectors to expand into, generate + probe candidate domains |
| `controller` | 16 KB | Agent orchestration: cron, delegation, parallel execution, memory |
| `attack-patterns-reference` 🔒 | 15 KB | Pattern catalog to match findings against |
| `hunt-dispatch` | 14 KB | Skill-set loader for `/hunt`; fingerprints target, loads RT or WAPT set |
| `sector-recon-methodology` | 14 KB | Pick sectors, compile targets, batch recon for campaigns |
| `worker` | 14 KB | Worker-cluster reference: tool inventory, SSH patterns, exec environment |
| `pentest-playbook` 🔒 | 8 KB | 7-phase pentest pipeline |
| `recon-sector` | 7 KB | Parameterized sector recon against the sector database |
| `cross-wave-delta-analysis` | 5 KB | Diff recon waves → NEW / REGRESSED / PERSISTENT findings |

### 4.2 Recon & discovery — 29

| Skill | Size | Purpose |
|---|---|---|
| `web2-recon` | 43 KB | subfinder/Chaos → dnsx/httpx → katana/gau → ffuf → LinkFinder; + monitoring |
| `offensive-osint` | 32 KB | Operational probes, wordlists, regexes, dorks for external red team |
| `hunt-subdomain` | 26 KB | Subdomain takeover incl. Azure regional-pool re-issue, Zendesk, Vercel |
| `hunt-tls-network` | 22 KB | TLS/DNS misconfig; opinionated about which of these actually pay |
| `hunt-source-leak` | 14 KB | Source maps, Swagger, `.env`/`.git`, webpack chunks, asset-manifest |
| `error-log-mining` | 14 KB | Mine `error_log` for creds, paths, SQL |
| `web-enumeration` | 11 KB | Sensitive files, path-traversal bypass, vhost enum, `.env`, Varnish |
| `staging-subdomain-hunt` | 11 KB | Find staging via crt.sh when prod is WAF-hardened |
| `js-secrets-extraction` | 10 KB | JS bundles + source maps → API keys, JWTs, internal endpoints |
| `subdomain-enumeration` | 10 KB | crt.sh + subfinder at recon kickoff |
| `gitlab-public-recon` | 10 KB | Mine GitLab for secrets and CI tokens |
| `iot-camera-recon` | 10 KB | RTSP / ONVIF / Axis config when 554 is open |
| `port-service-discovery` | 8 KB | Nmap for MySQL, Redis, FTP, SSH, internal APIs |
| `port-mass-scan` | 8 KB | Masscan + RustScan across /8–/24 with nmap banners |
| `source-leak-hunt` | 8 KB | Mass scan for exposed env files, backups, git configs |
| `scada-hikvision-isapi` | 8 KB | Hikvision ISAPI endpoint enumeration on SCADA/IoT |
| `github-secret-hunting` | 7 KB | Leaked keys/tokens/creds in public GitHub repos |
| `hardcoded-credential-hunt` | 7 KB | Hardcoded passwords in HTML forms, JS, API responses |
| `hunt-information-disclosure` | 7 KB | Error leakage, DVCS exposure, source maps, differential oracles |
| `cms-detection` | 7 KB | Fingerprint CMS, frameworks, server stack |
| `asn-infrastructure-mapping` | 6 KB | ASN → CIDR → TLD expansion → reverse DNS |
| `origin-ip-discovery` | 6 KB | Origin behind CDN/WAF via favicon hash, DNS history, SSL certs |
| `visual-recon` | 6 KB | Screenshot all live hosts for rapid visual triage |
| `vhost-enumeration` | 5 KB | Hidden vhosts via Host-header fuzzing + cert parsing |
| `subdomain-takeover-hunt` | 5 KB | Dangling CNAME → unclaimed service, detect and verify |
| `hunt-metrics-exposure` | 5 KB | Public `/metrics`, `/health`, actuator endpoints |
| `hunt-schema-enumeration` | 5 KB | Hidden tables/fields/endpoints via API error hints |
| `google-dorks-catalog` 🔒 | 4 KB | Validated high-precision dorks |
| `email-security` | 3 KB | DMARC/SPF/DKIM, spoofing, SMTP, security headers |

### 4.3 Injection & code execution — 11

| Skill | Size | Purpose |
|---|---|---|
| `hunt-rce` | 31 KB | Built from 67 public reports |
| `hunt-ssrf` | 26 KB | 15 reports: AWS/GCP/Azure metadata, DNS rebinding, gopher chains |
| `hunt-xxe` | 24 KB | 10 reports: SVG, PPTX/DOCX, SOAP, SAML, blind OOB, CosmicSting |
| `hunt-sqli` | 23 KB | 12 reports incl. modern ORM raw-fragment and second-order SOQL |
| `hunt-lfi` | 18 KB | LFI/RFI/traversal, log poisoning, PHP filter-chain RCE, wrappers |
| `hunt-ssti` | 16 KB | Jinja2, Twig, Freemarker, ERB, Velocity, Mako, Thymeleaf, Smarty |
| `hunt-ldap` | 16 KB | LDAP + XPath injection, blind attribute exfil, AD enumeration |
| `hunt-file-upload` | 9 KB | 10 bypass techniques → webshell RCE, SVG XSS, DOCX XXE, ZIP slip |
| `hunt-deserialization` | 8 KB | ysoserial, phpggc, pickle, BinaryFormatter, Marshal, Log4Shell |
| `hunt-nosqli` | 7 KB | Mongo operator injection, CouchDB, Redis command injection |
| `phpinfo-to-rce` | 8 KB | Chain exposed `info.php` to RCE |

### 4.4 AuthN / AuthZ / session / logic — 16

| Skill | Size | Purpose |
|---|---|---|
| `hunt-race-condition` | 44 KB | 12 reports; HTTP/2 single-packet attack, coupon/gift-card double-spend |
| `hunt-auth-bypass` | 35 KB | 12 reports: SAML XSW, sig stripping, JWT alg confusion, legacy endpoints |
| `hunt-oauth` | 28 KB | 19 public reports |
| `hunt-idor` | 23 KB | 26 public reports — the densest skill in the pack |
| `hunt-ato` | 23 KB | 9 distinct ATO paths plus chains |
| `hunt-business-logic` | 21 KB | 12 reports, heavy on demonstrated financial impact |
| `password-spray-methodology` | 20 KB | Enum → lockout detection → pattern gen → spray, all protocols |
| `hunt-session` | 19 KB | Fixation, invalidation gaps, JWT-as-session, refresh rotation, DBSC |
| `hunt-brute-force` | 19 KB | Rate-limit taxonomy; distinguishes lockout vs throttle vs shadow-throttle |
| `hunt-saml` | 13 KB | XSW, NameID comment injection, sig stripping, key confusion |
| `hunt-mfa-bypass` | 13 KB | 7 distinct MFA/2FA bypass patterns |
| `saml-sso-attack` | 10 KB | XSW, signature strip, metadata extraction |
| `jwt-attack` | 10 KB | Decode, forge, brute when Bearer auth is present |
| `hunt-mass-assignment` | 6 KB | Sensitive-field injection, ORM framework exploitation |
| `hunt-broken-function-level-auth` | 6 KB | Verb drift, route shadowing, transport gaps |
| `hunt-write-gap` | 5 KB | PATCH/POST/DELETE unprotected while GET is protected |

### 4.5 Client-side, cache & request-layer — 13

| Skill | Size | Purpose |
|---|---|---|
| `hunt-xss` | 29 KB | 174 public reports |
| `hunt-http-smuggling` | 27 KB | CL.TE, TE.CL, H2.CL, H2.TE |
| `hunt-csrf` | 26 KB | 15 reports incl. SameSite=Lax sibling bypass, GraphQL-via-GET |
| `hunt-cache-poison` | 22 KB | 10 reports incl. Kettle 2024 path-normalization WCD |
| `hunt-cors` | 21 KB | Origin reflection + credentials, null origin, regex bypass, preflight |
| `hunt-dom` | 17 KB | DOM clobbering, postMessage hijack, service workers, CSS exfil |
| `hunt-host-header` | 15 KB | Reset poisoning → ATO, routing-based SSRF, OAuth issuer poisoning |
| `cors-chain-automation` | 14 KB | Batch CORS probing at scale; filters the `ACAO: *` false positives |
| `hunt-open-redirect` | 10 KB | Including chains to OAuth token theft → ATO |
| `cache-attack` | 9 KB | CDN cache poisoning / deception when `X-Cache` is present |
| `s3-minio-content-type-xss` | 7 KB | Bucket Content-Type override → stored XSS on target origin |
| `hunt-prototype-pollution` | 6 KB | Client + server side → XSS, auth bypass, RCE |
| `cors-credential-wordpress` | 6 KB | WP CORS credential reflection → data theft |

### 4.6 APIs & modern protocols — 7

| Skill | Size | Purpose |
|---|---|---|
| `hunt-api-misconfig` | 24 KB | Mass assignment, JWT attacks, prototype pollution, verb tampering |
| `hunt-misc` | 24 KB | Built from 225 public reports — the long tail |
| `hunt-graphql` | 20 KB | 12 reports: node()/GID IDOR, batching DoS, cost bypass, field authz |
| `hunt-grpc` | 20 KB | Reflection enabled, metadata stripping, transcoding, Rapid Reset |
| `hunt-websocket` | 20 KB | CSWSH, origin validation, socket.io room authz, Upgrade smuggling |
| `api-noauth-hunt` | 9 KB | No-auth APIs → data theft and CRUD |
| `unauth-api-flow-hijack` | 7 KB | Multi-step API flows exploitable without credentials |

### 4.7 Framework & stack-specific — 10

| Skill | Size | Purpose |
|---|---|---|
| `hunt-sharepoint` | 33 KB | On-prem farms, ToolShell precondition chain (CVE-2025-53770) |
| `hunt-aspnet` | 22 KB | ViewState deserialization, machineKey recovery, trace/elmah |
| `hunt-nextjs` | 12 KB | Server Actions, middleware auth bypass, `/_next/image` SSRF |
| `hunt-nodejs` | 12 KB | Prototype pollution → RCE, trust proxy, SSTI, require() injection |
| `hunt-springboot` | 11 KB | Actuator heapdump/env, SpEL RCE, Jolokia, Spring4Shell |
| `hunt-laravel` | 9 KB | APP_DEBUG leak, Telescope/Horizon, Ignition RCE, signed URLs |
| `flask-werkzeug-attack` | 7 KB | Debugger exposure → traceback and SECRET leak |
| `hunt-nestjs` | 7 KB | Guard bypass, decorator gaps, microservice auth drift |
| `hunt-fastapi` | 6 KB | DI gaps, Pydantic coercion, OpenAPI mining |
| `hunt-django` | 5 KB | DRF permission gaps, ORM injection, admin exploitation |

### 4.8 Enterprise identity & appliances — 7

| Skill | Size | Purpose |
|---|---|---|
| `vmware-vcenter-attack` | 32 KB | vSphere/vCenter CVE chain, vmdir LDAP, default creds |
| `okta-attack` | 25 KB | Tenant discovery, user enum, push fatigue, FastPass abuse |
| `m365-entra-attack` | 22 KB | AADSTS reference, Smart Lockout math, CA bypass, ROPC + SAML |
| `enterprise-vpn-attack` | 20 KB | Cisco/Fortinet/Citrix/Palo Alto/Ivanti/SonicWall/F5, CVEs 2018–2026 |
| `hunt-ntlm-info` | 17 KB | Anonymous NTLM Type-2 → domain, forest, hostname, AD timestamp |
| `exchange-owa-attack` | 11 KB | NTLM AD leak + spray against mail subdomains |
| `zimbra-attack` | 9 KB | SOAP user enum, CVE-2022-37042, SSRF |

### 4.9 Cloud, containers, CI/CD, supply chain — 9

| Skill | Size | Purpose |
|---|---|---|
| `supply-chain-attack-recon` | 40 KB | Dependency confusion, namespace squatting, SBOM mining — recon only |
| `hunt-k8s` | 21 KB | API anon access, kubelet 10250 exec, etcd 2379, Leaky Vessels |
| `hunt-cicd` | 19 KB | Actions injection, runner poisoning, OIDC trust, Jenkins RCE |
| `hunt-firebase` | 17 KB | API key discovery → anon auth → Firestore enumeration |
| `hunt-supabase` | 17 KB | Anon key → REST table enum, RLS bypass, RPC abuse, storage |
| `firebase-supabase-attack` | 15 KB | JS config leak → Firebase/Supabase data access |
| `hunt-cloud-misconfig` | 13 KB | S3/GCS/Blob, Lambda URLs, IMDS-via-SSRF, public snapshots |
| `cloud-iam-deep` | 9 KB | Post-credential escalation across GCP/AWS/Azure |
| `docker-privesc` 🔒 | 7 KB | Container escape to host root |

### 4.10 WordPress cluster — 10

| Skill | Size | Purpose |
|---|---|---|
| `hunt-wordpress` | 70 KB | The main one: REST enum, XMLRPC, CORS reflect, plugin CVEs, wp-config |
| `wordpress-full-compromise` 🔒 | 25 KB | Optimal full-compromise kill chains |
| `deep-invade` | 18 KB | Deep WP pentest: SSRF, plugin CVE, JS mining, port-scan chain |
| `xmlrpc-exploitation` | 18 KB | multicall + pingback → brute force and SSRF |
| `wordpress-cors-xmlrpc-rce-chain` | 16 KB | Proven CORS + XMLRPC + open-registration → RCE chain |
| `wp-plugin-cve-hunt` | 14 KB | Version extraction → WPScan/Patchstack/NVD matching → PoC |
| `wordpress-plugin-hunt` | 13 KB | Plugin discovery via REST, exploit when version known |
| `wp-mass-recon` | 12 KB | Batch WP recon across domains |
| `wp-plugin-automation` | 9 KB | Batch-test popular plugin CVEs across hundreds of domains |
| `wp-plugin-rest-auth-bypass` | 8 KB | Unauthenticated state-changing REST plugin endpoints |

### 4.11 AI / LLM security — 3

| Skill | Size | Purpose |
|---|---|---|
| `llm-prompt-injection` | 28 KB | 40+ techniques vs hardened deployments; GeminiJack, EchoLeak, Reprompt |
| `hunt-llm-ai` | 28 KB | Prompt injection, ASCII smuggling, agentic AI (OWASP ASI01–ASI10) |
| `hunt-mcp-security` | 8 KB | Model Context Protocol vulns in AI-tool integrations |

### 4.12 Web3 — 2

| Skill | Size | Purpose |
|---|---|---|
| `web3-audit` | 24 KB | 10 DeFi bug classes, kill signals, Foundry PoC template |
| `meme-coin-audit` | 16 KB | Rug-pull detection, SPL/Token-2022 risks, DEX pool attacks |

### 4.13 Mobile — 1

| Skill | Size | Purpose |
|---|---|---|
| `apk-redteam-pipeline` | 20 KB | APK acquisition → jadx → secret grep → Frida → intent injection |

### 4.14 OPSEC, evasion & tooling — 5

| Skill | Size | Purpose |
|---|---|---|
| `ops-proxyns` | 9 KB | Kernel-level proxy via network namespaces; works where proxychains fails |
| `http2-header-impersonation` | 9 KB | Spoof HTTP/2 SETTINGS frames and pseudo-header order |
| `humanize-automation` | 8 KB | Human-like mouse/keyboard/scroll for behavioural bot bypass |
| `stealth-browser-launch` | 8 KB | Stealth Chromium with C++ fingerprint patches |
| `tls-fingerprint-impersonation` | 8 KB | Spoof ClientHello / JA4 fingerprints |

### 4.15 Validation & reporting — 6

| Skill | Size | Purpose |
|---|---|---|
| `bugcrowd-reporting` | 26 KB | VRT search-and-fallback, severity override, OOS rebuttal templates |
| `evidence-hygiene` | 23 KB | Cookie redaction, PII black-bars, HAR sanitisation, screenshot order |
| `report-writing` | 23 KB | H1/Bugcrowd/Intigriti/Immunefi templates, CVSS 3.1, impact-first tone |
| `triage-validation` | 20 KB | 7-Question Gate before writing anything. One wrong answer = kill it |
| `mid-engagement-ir-detection` | 18 KB | Detect client SOC patching / third-party activity mid-engagement |
| `redteam-report-template` | 16 KB | Client deliverable format (not platform reports) — different audience |

---

## 5. Links

### The pack itself
- **Upstream repo:** https://github.com/uphiago/recon-skills — "curated collection of security testing procedures … for authorized security testing only" (1.2k stars)
- **Local install:** `~/.claude/skills/` — flattened, one directory per skill, no `.git` (not a clone, so `git pull` will not update it)
- **Re-sync:** clone upstream to a temp dir, copy skill directories over the top, then re-apply the frontmatter fixes noted in section 3

### Anthropic documentation
- Agent Skills overview: https://docs.claude.com/en/docs/agents-and-tools/agent-skills
- Claude Code settings: https://docs.claude.com/en/docs/claude-code/settings

### External tools and research cited across the corpus
66 unique repositories are referenced. The load-bearing ones:

**Payloads & wordlists**
- https://github.com/swisskyrepo/PayloadsAllTheThings
- https://github.com/danielmiessler/SecLists
- https://github.com/fuzzdb-project/fuzzdb
- https://github.com/six2dez/OneListForAll
- https://github.com/assetnote/commonspeak2-wordlists
- https://github.com/bo0om/wordlists
- https://github.com/ihebski/DefaultCreds-cheat-sheet
- https://github.com/tomnomnom/gf

**Recon**
- https://github.com/projectdiscovery/subfinder
- https://github.com/owasp-amass/amass
- https://github.com/laramies/theHarvester
- https://github.com/lanmaster53/recon-ng
- https://github.com/six2dez/reconftw
- https://github.com/robertdavidgraham/masscan
- https://github.com/maurosoria/dirsearch
- https://github.com/GerbenJavado/LinkFinder
- https://github.com/pry0cc/axiom
- https://github.com/initstring/cloud_enum
- https://github.com/webrecorder/browsertrix-crawler

**OSINT / people**
- https://github.com/sherlock-project/sherlock
- https://github.com/soxoj/maigret
- https://github.com/megadose/holehe
- https://github.com/sundowndev/phoneinfoga
- https://github.com/m8r0wn/CrossLinked
- https://github.com/snscrape/snscrape
- https://github.com/Proviesec/github-dorks

**Exploitation**
- https://github.com/frohoff/ysoserial (Java deserialization)
- https://github.com/ambionics/phpggc (PHP object injection)
- https://github.com/synacktiv/php_filter_chain_generator (LFI → RCE)
- https://github.com/pimps/JNDI-Exploit-Kit
- https://github.com/ambionics/laravel-ignition-rce
- https://github.com/defparam/smuggler + https://github.com/assetnote/h2csmuggler
- https://github.com/secengjeff/rapidresetclient (CVE-2023-44487)
- https://github.com/sinsinology/CVE-2023-20887 (VMware Aria)
- https://github.com/arthaud/git-dumper + https://github.com/lijiejie/ds_store_exp
- https://github.com/RhinoSecurityLabs/pacu (AWS post-exploitation)
- https://github.com/gremwell/o365enum + https://github.com/knavesec/CredMaster

**Fingerprinting & analysis**
- https://github.com/salesforce/ja3 + https://github.com/FingerprinTLS/ja4
- https://github.com/drwetter/testssl.sh
- https://github.com/skylot/jadx (APK decompilation)
- https://github.com/mandiant/capa + https://github.com/mandiant/flare-floss
- https://github.com/trickest/cve

**Methodology**
- https://github.com/KathanP19/HowToHunt
- https://github.com/aquasecurity/cloudsploit

---

## 6. Reference: quick lookup by finding type

Saw something, need the right skill:

| You observed | Load |
|---|---|
| `Access-Control-Allow-Origin` reflecting your Origin | `hunt-cors` |
| Numeric/UUID object ref in a URL or body | `hunt-idor` |
| A JWT in `Authorization` | `jwt-attack`, `hunt-api-misconfig` |
| `AIzaSy…` in a JS bundle | `hunt-firebase` |
| `supabase.co` / anon key | `hunt-supabase` |
| `X-Cache` / CDN headers | `cache-attack`, `hunt-cache-poison` |
| `/actuator` or `X-Application-Context` | `hunt-springboot` |
| `WWW-Authenticate: NTLM` | `hunt-ntlm-info` |
| `/graphql` responding | `hunt-graphql` |
| `.js.map` reachable | `hunt-source-leak` |
| `wp-json` / `xmlrpc.php` | `hunt-wordpress` |
| Forgot-password flow | `hunt-host-header`, `hunt-ato` |
| Price / quantity / coupon field | `hunt-business-logic`, `hunt-race-condition` |
| File upload form | `hunt-file-upload` |
| SSL VPN login portal | `enterprise-vpn-attack` |
| An LLM-backed feature | `hunt-llm-ai`, `llm-prompt-injection` |
| GET protected but PATCH is not | `hunt-write-gap` |

---

*Authorized testing only. Every skill in this pack assumes you have permission for the target in front of you.*
