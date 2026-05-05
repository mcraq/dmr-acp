# FR-005: Error Handling & Resilience

**Feature Area:** Error Handling  
**MoSCoW:** Must Have (error mapping, signal handling), Should Have (retry, degradation)  
**Rationale:** Errors must be surfaced to the IDE as valid JSON-RPC error responses. Unhandled errors or panics will cause JetBrains to silently disconnect.

---

## Requirements

### FR-005.1 — JSON-RPC Error Mapping
**Must Have**  
All error conditions MUST produce a valid JSON-RPC error response. Required mappings:

| Condition | Error Code | Message |
|---|---|---|
| Docker unreachable | `-32001` | "Docker Model Runner not detected on :12434" |
| Model not found | `-32602` | "Model not found. Please run 'docker model pull \<model\>'." |
| Inference timeout | `-32000` | "Local inference timed out." |
| Malformed JSON-RPC | `-32700` | "Parse error" |
| Unknown method | `-32601` | "Method not found" |
| Internal panic/error | `-32603` | "Internal error" |

### FR-005.2 — SIGINT / SIGTERM Handling
**Must Have**  
The bridge MUST handle `os.Interrupt` (`SIGINT`) and `syscall.SIGTERM`:
- Cancel all active inference requests to Docker.
- Close all open sessions cleanly.
- Exit with code 0.
- Exit with a non-zero code on unrecoverable error.

### FR-005.3 — Active Inference Cancellation on Shutdown
**Must Have**  
On receiving a shutdown signal, any in-progress Docker SSE stream MUST be cancelled via `context.CancelFunc`. Goroutines MUST exit cleanly without orphaned HTTP connections.

### FR-005.4 — Orphaned Stream Cleanup on Client Disconnect
**Must Have**  
If the IDE closes `stdin` unexpectedly, the bridge MUST detect EOF and cancel all active sessions and their associated Docker streams before exiting.

### FR-005.5 — Inference Timeout
**Must Have**  
Each inference request to Docker MUST be subject to a configurable timeout (default: 60s). On expiry, the bridge MUST cancel the request and return error `-32000` to the client.

### FR-005.6 — Panic Recovery
**Must Have**  
A top-level `recover()` MUST catch panics in request-handling goroutines, log the stack trace to `stderr`, and return error `-32603` rather than crashing the bridge.

### FR-005.7 — Connection Retry with Exponential Backoff
**Should Have**  
If the Docker endpoint is temporarily unreachable, the bridge SHOULD retry with exponential backoff (e.g., 100ms, 200ms, 400ms, max 3 attempts) before returning `-32001`.

### FR-005.8 — Partial Response Recovery
**Should Have**  
If a Docker SSE stream is interrupted after partial tokens have been delivered, the bridge SHOULD emit the tokens received so far, then send a `session/prompt/error` notification rather than silently dropping the partial response.

### FR-005.9 — Model Not Found — Pull Hint
**Could Have**  
When returning a model-not-found error, the bridge COULD include the specific `docker model pull <model>` command in the error message, derived from the requested model name.

---

## Acceptance Criteria

- Taking Docker offline mid-stream returns `-32001` to the client within the timeout period.
- `SIGTERM` with an active streaming session exits cleanly (code 0, no orphaned processes).
- Sending malformed JSON on `stdin` returns `-32700` without crashing the bridge.
- A panicking request handler is recovered; the bridge continues serving other sessions.
- All error responses are valid JSON-RPC 2.0 error objects.
