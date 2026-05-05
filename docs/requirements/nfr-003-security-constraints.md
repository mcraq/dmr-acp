# NFR-003: Security Constraints

**Feature Area:** Security  
**MoSCoW:** Should Have (host restriction, size limits, timeout guard), Could Have (rate limiting)  
**Rationale:** These constraints are quality attributes on the bridge's security posture — they limit blast radius and resource exhaustion but do not define observable behaviours in the happy path.

---

## Requirements

### NFR-003.1 — Localhost-Only Docker Host (Default)
**Should Have**  
By default, the Docker host SHOULD be restricted to `localhost` / `127.0.0.1`. Non-local hosts SHOULD require explicit opt-in (e.g., `--allow-remote-docker` flag) and log a warning.

### NFR-003.2 — Prompt Size Limit
**Should Have**  
Incoming prompts SHOULD be subject to a configurable maximum byte size (default: 1MB) to prevent resource exhaustion. Requests exceeding the limit SHOULD return a JSON-RPC error.

### NFR-003.3 — Timeout as Resource Exhaustion Guard
**Should Have**  
The inference timeout (see FR-006.2) SHOULD also serve as a resource exhaustion guard, preventing a single stalled request from holding a goroutine and Docker connection indefinitely.

### NFR-003.4 — Rate Limiting
**Could Have**  
The bridge COULD implement per-session rate limiting on `session/prompt` requests (e.g., max N concurrent inferences) to prevent runaway clients from saturating Docker.

---

## Acceptance Criteria

- Connecting to a non-localhost Docker host logs a warning to `stderr`.
- Sending a prompt exceeding 1MB returns a JSON-RPC error without forwarding to Docker.
- A stalled Docker inference is cancelled after the configured timeout; the goroutine exits cleanly.
- With rate limiting enabled, a client exceeding the concurrent inference limit receives a JSON-RPC error immediately.
