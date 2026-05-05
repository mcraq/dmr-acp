# NFR-001: Performance & Scalability

**Feature Area:** Performance  
**MoSCoW:** Must Have (latency targets, memory footprint, binary size), Should Have (efficiency optimisations), Could Have (tuning)  
**Rationale:** As a subprocess, the bridge must impose negligible overhead. Users should not perceive any latency attributable to the bridge itself.

---

## Requirements

### NFR-001.1 — Handshake Latency
**Must Have**  
The `initialize` response MUST be sent within **50ms** of receiving the request. This includes the Docker model discovery call.

### NFR-001.2 — Per-Token Streaming Overhead
**Must Have**  
The bridge MUST introduce no more than **50ms** of additional latency per token between receiving an SSE chunk from Docker and writing the corresponding `session/prompt/chunk` notification to `stdout`.

### NFR-001.3 — Memory Footprint
**Must Have**  
Resident Set Size (RSS) MUST remain below **20MB** under typical single-session load.

### NFR-001.4 — Binary Size
**Must Have**  
The compiled static binary MUST be smaller than **15MB** (built with `CGO_ENABLED=0 -ldflags '-s -w'`).

### NFR-001.5 — Concurrent Session Support
**Should Have**  
The bridge SHOULD handle multiple simultaneous streaming sessions without degradation, limited only by Docker's VRAM capacity and the host's network stack.

### NFR-001.6 — Connection Pooling
**Should Have**  
The bridge SHOULD reuse HTTP connections to Docker via a persistent `http.Transport` connection pool, reducing per-request TCP and TLS overhead.

### NFR-001.7 — Zero-Copy Streaming
**Should Have**  
The SSE → ACP chunk pipeline SHOULD avoid unnecessary buffer copies. Tokens SHOULD be wrapped and written without intermediate allocations where possible.

### NFR-001.8 — Lazy Session Initialization
**Should Have**  
Heavy session resources (e.g., preallocated history buffers) SHOULD be initialized lazily on the first `session/prompt`, not at `session/new`.

### NFR-001.9 — Configurable GOMAXPROCS
**Could Have**  
`GOMAXPROCS` SHOULD be configurable via environment variable to allow CPU pinning in resource-constrained environments.

---

## Acceptance Criteria

- `initialize` roundtrip (including Docker model query) completes in < 50ms on localhost.
- Token-to-chunk latency measured at < 50ms p99 over a 100-token response.
- `ps` or `top` shows RSS < 20MB under single-session load.
- `ls -lh ./dmr-acp-bridge` shows < 15MB after optimised build.
- Two concurrent 200-token streaming sessions complete without either blocking the other.
