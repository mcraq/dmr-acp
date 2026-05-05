# FR-002: Docker Model Runner Integration

**Feature Area:** Core Protocol — Southbound  
**MoSCoW:** Must Have  
**Rationale:** The bridge's sole model backend is Docker Model Runner. Without this integration, no inference is possible.

---

## Requirements

### FR-002.1 — Chat Completion API
**Must Have**  
The bridge MUST send prompt requests to Docker via:
```
POST http://localhost:12434/v1/chat/completions
```
with an OpenAI-compatible request body including a `messages` array and `stream: true`.

### FR-002.2 — Model Discovery
**Must Have**  
The bridge MUST query:
```
GET http://localhost:12434/v1/models
```
during `initialize` to populate `availableModels`. The response model list MUST be passed to the ACP client as-is.

### FR-002.3 — SSE Streaming
**Must Have**  
The bridge MUST consume `text/event-stream` (Server-Sent Events) from Docker:
- Parse each `data: {...}` line and extract `choices[0].delta.content`.
- Forward each token as a `session/prompt/chunk` notification.
- Terminate the stream cleanly on the `data: [DONE]` sentinel.

### FR-002.4 — Configurable Docker Host
**Must Have**  
The Docker host and port MUST be configurable via `--docker-host` CLI flag and `DMR_HOST` environment variable. Default: `http://localhost:12434`.

### FR-002.5 — Connection Pooling
**Should Have**  
The bridge SHOULD reuse HTTP connections to Docker via an `http.Client` with a persistent connection pool to reduce per-request latency.

### FR-002.6 — Docker Availability Check
**Should Have**  
The bridge SHOULD perform a health check against the Docker endpoint on startup, logging a clear warning to `stderr` if Docker is unreachable rather than silently waiting for the first request to fail.

### FR-002.7 — Multiple Concurrent Requests
**Should Have**  
The bridge SHOULD support multiple simultaneous inference requests to Docker (e.g., from concurrent sessions), limited in practice by DMR's available VRAM.

---

## Acceptance Criteria

- A `session/prompt` successfully returns streamed tokens from a running Docker Model Runner.
- `availableModels` in the `initialize` response matches `GET /v1/models` output.
- DMR offline at startup logs a warning to `stderr` (not `stdout`) and returns error `-32001` on first prompt.
- Docker host is overridable without recompiling the binary.
