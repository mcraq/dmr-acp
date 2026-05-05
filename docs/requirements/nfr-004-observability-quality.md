# NFR-004: Observability Quality Attributes

**Feature Area:** Observability  
**MoSCoW:** Must Have (configurable log levels), Should Have (structured fields, timing), Could Have (metrics, health polling)  
**Rationale:** These are quality attributes on the bridge's observability — they improve diagnostic usefulness and developer experience but do not affect protocol correctness.

---

## Requirements

### NFR-004.1 — Configurable Log Levels
**Must Have**  
The bridge MUST support at minimum `debug`, `info`, `warn`, and `error` log levels, selectable via `--debug` flag or `LOG_LEVEL` environment variable.

### NFR-004.2 — Request Trace IDs
**Should Have**  
Each JSON-RPC request SHOULD be assigned a trace ID (UUID or incrementing counter) that is included in all log lines for that request, enabling correlation across log lines.

### NFR-004.3 — Stream Timing Logs
**Should Have**  
The bridge SHOULD log time-to-first-token (TTFT) and total stream duration at `debug` level, to help identify performance issues with specific models.

### NFR-004.4 — Active Session Count Metric
**Could Have**  
The bridge COULD expose a live count of active sessions via a `session/debug` JSON-RPC extension or a local HTTP metrics endpoint (`/metrics`), useful for monitoring during development.

### NFR-004.5 — Docker Connection Health Polling
**Could Have**  
The bridge COULD periodically log Docker connection health (e.g., every 30s at `debug` level) to surface connectivity issues before they affect a prompt.

---

## Acceptance Criteria

- Running with `LOG_LEVEL=debug` produces structured log lines on `stderr` including `traceId` and `sessionId` fields.
- Running with `LOG_LEVEL=error` suppresses info and debug lines.
- At `debug` level, TTFT is logged for each completed streaming response.
- `GET /metrics` (if implemented) returns a JSON or Prometheus-format count of active sessions.
- Docker health log lines appear at `debug` level at the configured polling interval.
