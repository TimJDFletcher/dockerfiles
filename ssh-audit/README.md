# ssh-audit

Docker container for [ssh-audit](https://github.com/jtesta/ssh-audit), an SSH server and client security auditing tool.

## Quick Start

```bash
# Audit any SSH server
docker run --rm timjdfletcher/ssh-audit example.com

# Audit on a non-standard port
docker run --rm timjdfletcher/ssh-audit -p 2222 example.com

# JSON output for scripting
docker run --rm timjdfletcher/ssh-audit --json example.com

# Generate a policy from a known-good server
docker run --rm timjdfletcher/ssh-audit -M /dev/stdout example.com > policy.txt
```

## Finding Good sshd Settings

This container includes example configurations demonstrating secure vs insecure SSH settings.

### Hardened Configuration (Passes with Exit 0)

The `test-configs/secure-sshd_config` demonstrates a configuration that passes ssh-audit with no warnings or failures:

```bash
# Key Exchange - Strong algorithms only
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512

# Ciphers - AEAD and CTR modes only, no CBC
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

# MACs - ETM mode, SHA-2 only, no small tags
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com

# Host Keys - Ed25519 and RSA with SHA-2 only (no ECDSA NIST curves)
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
```

**Why these settings are secure:**
- **No NIST curves** - ECDSA NIST P-256/384/521 curves are suspected of NSA backdoors
- **No SHA-1** - Broken hash algorithm, deprecated
- **No CBC ciphers** - Vulnerable to padding oracle attacks
- **No small MAC tags** - 64-bit tags are too small for modern security
- **ETM mode only** - Encrypt-then-MAC is more secure than encrypt-and-MAC

### Weak Configuration (Fails Audit)

The `test-configs/weak-sshd_config` demonstrates insecure settings that ssh-audit will flag:

```bash
# AVOID THESE - Weak/deprecated algorithms
KexAlgorithms diffie-hellman-group1-sha1,ecdh-sha2-nistp256
Ciphers 3des-cbc,aes128-cbc,aes256-cbc
MACs hmac-sha1,hmac-md5,hmac-sha1-96
```

**Why these are flagged:**
- `diffie-hellman-group1-sha1` - Uses 1024-bit group (too small) and SHA-1
- `ecdh-sha2-nistp*` - NIST curves with suspected backdoors
- `3des-cbc` - 64-bit block size, vulnerable to Sweet32
- `*-cbc` - CBC mode vulnerable to padding oracles
- `hmac-md5`, `hmac-sha1` - Broken hash algorithms

## Auditing Your Server

```bash
# Basic audit
docker run --rm timjdfletcher/ssh-audit your-server.com

# Exit codes:
#   0 = No issues found
#   1 = Warnings only
#   2 = Failures found
#   3 = Critical issues

# Check exit code in scripts
docker run --rm timjdfletcher/ssh-audit your-server.com
if [ $? -eq 0 ]; then
    echo "SSH configuration is secure"
else
    echo "SSH configuration needs hardening"
fi
```

## Generating a Baseline Policy

Create a policy from a server with known-good configuration, then use it to audit other servers:

```bash
# Generate policy from golden server
docker run --rm timjdfletcher/ssh-audit -M /dev/stdout golden-server.com > ssh-policy.txt

# Audit other servers against the policy
docker run --rm -v $(pwd):/policies timjdfletcher/ssh-audit -P /policies/ssh-policy.txt target-server.com
```

## CI/CD Integration

```yaml
# GitHub Actions example
- name: Audit SSH Configuration
  run: |
    docker run --rm timjdfletcher/ssh-audit --json ${{ secrets.SSH_HOST }} > audit.json
    if [ $? -ne 0 ]; then
      echo "SSH audit failed"
      exit 1
    fi
```

## Auditing a Local Network

ssh-audit doesn't support CIDR notation directly - it requires a targets file with one host per line. Here's how to scan a subnet.

### Generate a Targets File

```bash
# Bash brace expansion - no external tools needed (scans all IPs)
printf '%s\n' 192.168.1.{1..254} > targets.txt

# Or use nmap to find only live hosts first (faster, fewer timeouts)
nmap -sn 192.168.1.0/24 -oG - | awk '/Up/{print $2}' > targets.txt

# Or use your ARP cache for recently-seen hosts
arp -a | grep '192.168.1' | awk -F'[()]' '{print $2}' > targets.txt

# Manual list of known hosts
cat > targets.txt << 'EOF'
192.168.1.1
192.168.1.10
192.168.1.20
EOF
```

### Scan All Targets

```bash
# Basic network scan (default 32 threads)
docker run --rm \
  -v $(pwd):/data:ro \
  timjdfletcher/ssh-audit -T /data/targets.txt

# Limit concurrent connections to avoid rate-limiting
docker run --rm \
  -v $(pwd):/data:ro \
  timjdfletcher/ssh-audit -T /data/targets.txt --threads 4

# JSON output for processing with jq
docker run --rm \
  -v $(pwd):/data:ro \
  timjdfletcher/ssh-audit -T /data/targets.txt --json > network-audit.json
```

### Extract Findings from JSON

```bash
# List all targets with failures
cat network-audit.json | jq -r '.[] | select(.recommendations.critical) | .target'

# Show recommendations for each host
cat network-audit.json | jq -r '.[] | "\(.target): \(.recommendations)"'

# Count hosts by SSH version
cat network-audit.json | jq -r '.[].banner.software' | sort | uniq -c
```

### Network Audit Script Example

```bash
#!/bin/bash
# audit-network.sh - Audit all SSH servers on local network

NETWORK_PREFIX="192.168.1"
TARGETS=$(mktemp)
RESULTS=$(mktemp)

# Generate all IPs in subnet
printf '%s\n' ${NETWORK_PREFIX}.{1..254} > "$TARGETS"

echo "Scanning ${NETWORK_PREFIX}.0/24 for SSH servers..."

# Run audit (ssh-audit handles connection failures gracefully)
docker run --rm \
  -v "$TARGETS":/targets.txt:ro \
  timjdfletcher/ssh-audit -T /targets.txt --threads 8 --json 2>/dev/null > "$RESULTS"

# Summary
TOTAL=$(jq -r '[.[] | select(.banner.protocol != null)] | length' "$RESULTS")
CRITICAL=$(jq -r '[.[] | select(.recommendations.critical)] | length' "$RESULTS")
WARNINGS=$(jq -r '[.[] | select(.recommendations.warning and (.recommendations.critical | not))] | length' "$RESULTS")

echo ""
echo "=== Audit Summary ==="
echo "SSH servers found: $TOTAL"
echo "Critical issues:   $CRITICAL"
echo "Warnings only:     $WARNINGS"

if [ "$CRITICAL" -gt 0 ]; then
  echo ""
  echo "Hosts with critical issues:"
  jq -r '.[] | select(.recommendations.critical) | "  - \(.target)"' "$RESULTS"
fi

# Cleanup
rm -f "$TARGETS" "$RESULTS"
```

### Non-Standard Ports

```bash
# Scan hosts on different ports (HOST:PORT format)
cat > targets.txt << 'EOF'
192.168.1.1:22
192.168.1.10:2222
192.168.1.20:22222
EOF

docker run --rm -v $(pwd):/data:ro timjdfletcher/ssh-audit -T /data/targets.txt

# Or set a default port for all hosts
printf '%s\n' 192.168.1.{1..254} > targets.txt
docker run --rm -v $(pwd):/data:ro timjdfletcher/ssh-audit -T /data/targets.txt -p 2222
```

## References

- [ssh-audit GitHub](https://github.com/jtesta/ssh-audit)
- [Mozilla SSH Guidelines](https://infosec.mozilla.org/guidelines/openssh)
- [SSH Hardening Guides](https://www.ssh-audit.com/hardening_guides.html)
