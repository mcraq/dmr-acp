# FR-004: Streaming & I/O

**Feature Area:** Streaming & I/O  
**MoSCoW:** Must Have (core), Should Have (buffering tuning)  
**Rationale:** Streaming is the primary delivery mechanism for inference responses. Correct, non-blocking I/O is essential for IDE compatibility.

---

## Requirements

### FR-004.1 — SSE Parsing
**Must Have**  
The bridge MUST parse `text/event-stream` responses from Docker:
- Read each `data: <json>` line.
- Extract `choices[0].delta.content` from the JSON payload.
- Ignore `data: [DONE]` and comment lines (starting with `:`).

### FR-004.2 — ACP Chunk Wrapping
**Must Have**  
Each extracted token MUST be immediately wrapped in a `session/prompt/chunk` JSON-RPC notification and written to `stdout`.

### FR-004.3 — Atomic Flushing
**Must Have**  
After every JSON-RPC message written to `stdout`, `bufio.Writer.Flush()` MUST be called. Partial buffering MUST NOT occur; JetBrains will disconnect if the pipe stalls.

### FR-004.4 — Non-Blocking Pipeline
**Must Have**  
The SSE read loop MUST be non-blocking with respect to other sessions. Each session's stream MUST run in its own goroutine so one slow or stalled session does not block others.

### FR-004.5 — Stream Termination
**Must Have**  
On receiving `data: [DONE]` from Docker, the bridge MUST send a final `session/prompt` result response (not a chunk notification) and close the stream cleanly.

### FR-004.6 — Configurable Buffer Size
**Should Have**  
The chunk read buffer size SHOULD be configurable (e.g., via `--buffer-size` or environment variable) to allow tuning for different network/local throughput characteristics. Default: 4KB.

### FR-004.7 — Connection Keep-Alive
**Should Have**  
The HTTP connection to Docker SHOULD use keep-alive to avoid TCP handshake overhead on consecutive streaming requests.

### FR-004.8 — Partial Chunk Recovery
**Should Have**  
If a Docker SSE stream is interrupted mid-token, the bridge SHOULD not drop the partial chunk; instead it SHOULD emit whatever was received and then report a stream error.

---

## Acceptance Criteria

- Streaming a 500-token response produces exactly 500 `session/prompt/chunk` notifications (one per token).
- No `session/prompt/chunk` notifications are emitted after `[DONE]`.
- Closing a stream on one session does not delay or drop chunks on a concurrent session.
- `stdout` never contains partial JSON; every line is a complete, parseable JSON-RPC message.
