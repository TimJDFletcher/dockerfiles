# TODO

## Docker Image Signing (In Progress)

**Goal:** Sign container images at release time for supply chain security.

### Tool: Cosign (Sigstore)

Installed via `brew install cosign` (v3.0.5). Modern OCI-native signing standard.

### Key Storage Options

| Option | Pros | Cons |
|--------|------|------|
| **YubiKey PIV** | Hardware-backed, touch to sign | Uses PIV applet (separate from GPG key) |
| **File-based** | Simple setup | Must protect private key file |
| **GPG-wrapped** | Leverages existing GPG key | Extra decrypt step at sign time |

**Note:** Cosign uses the **PIV applet** on YubiKey, not the OpenPGP applet where GPG keys live. These are separate key stores on the same hardware.

### YubiKey PIV Setup (if chosen)

```bash
brew install ykman                          # YubiKey Manager
cosign generate-key-pair --sk               # Generate key in PIV slot
cosign sign --sk <IMAGE_DIGEST>             # Sign with hardware key
cosign verify --key cosign.pub <IMAGE>      # Verify signature
```

### Proposed Interface

```bash
./run sign      # Sign image after release
./run verify    # Verify signature exists
```

Or integrate signing into `./run release` flow.

### TDD Test Cases

1. Cosign binary is available
2. Image can be signed after push
3. Signature can be verified
4. Unsigned images fail verification

### Next Steps

1. Decide on key storage approach (YubiKey PIV vs file-based)
2. If YubiKey PIV: install ykman, generate key in PIV slot
3. Implement signing in `yajsv` project as pilot (simplest release process)
4. Add `sign` and `verify` commands to `./run`
5. Document in AGENTS.md
