# NFR-002: Portability & Deployment Constraints

**Feature Area:** Portability  
**MoSCoW:** Must Have (static binary, no runtime dependency), Should Have (cross-platform targets)  
**Rationale:** The binary must be deployable without a Go runtime and run identically across the target platforms supported by JetBrains IDEs and Docker Desktop.

---

## Requirements

### NFR-002.1 — Static Binary
**Must Have**  
The binary MUST be statically linked (`CGO_ENABLED=0`), requiring no Go runtime or shared libraries on the target system.

### NFR-002.2 — Binary Size Constraint
**Must Have**  
Binary size MUST be < 15MB (built with `CGO_ENABLED=0 -ldflags '-s -w'`). This constraint applies to all release targets.

### NFR-002.3 — No Go Runtime Dependency
**Must Have**  
The binary MUST run on a host with no Go toolchain installed. All dependencies MUST be compiled in.

### NFR-002.4 — Cross-Platform Support
**Should Have**  
The bridge SHOULD be buildable and functional on:
- Linux amd64
- Linux arm64
- macOS arm64
- macOS amd64
- Windows amd64

---

## Acceptance Criteria

- `ldd ./dmr-acp-bridge` on Linux shows no dynamic dependencies (or only kernel vDSO).
- `ls -lh ./dmr-acp-bridge` shows < 15MB after `go build -ldflags '-s -w'`.
- Binary runs on a Linux host with no Go installation.
- CI produces release artifacts for all five target platforms without errors.
