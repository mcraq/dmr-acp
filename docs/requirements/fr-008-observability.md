# FR-008: Observability & Debugging

**Feature Area:** Observability  
**MoSCoW:** Must Have (stderr logging, error logging), Should Have (debug logging)  
**Rationale:** Silent failures are the hardest to debug in a subprocess-based architecture. Useful, structured observability is essential for developer experience.

---

## Requirements

### FR-008.1 — Stderr Logging
**Must Have**  
All log output MUST go exclusively to `stderr`. `stdout` MUST contain only valid JSON-RPC. This is a strict ACP requirement.

### FR-008.2 — Request / Response Logging
**Should Have**  
At `debug` level, the bridge SHOULD log incoming JSON-RPC requests and outgoing responses (excluding prompt content body to avoid noise).

### FR-008.3 — Stream Event Logging
**Should Have**  
At `debug` level, the bridge SHOULD log SSE events received from Docker (token count, bytes, timing) to aid in diagnosing streaming issues.

### FR-008.4 — Error & Stack Trace Logging
**Must Have**  
All errors MUST be logged to `stderr` with enough context to identify the failing component. Recovered panics MUST log the full stack trace.

### FR-008.5 — Session Context in Logs
**Should Have**  
Log lines related to a session SHOULD include the `sessionId` for filtering (e.g., `sessionId=sess_abc123`).

---

## Acceptance Criteria

- No log output appears on `stdout` under any log level.
- A failed Docker request logs the error code, HTTP status, and session context to `stderr`.
- A recovered panic logs the full goroutine stack trace before returning `-32603` to the client.
- At `debug` level, log lines for a session include the `sessionId` field.

