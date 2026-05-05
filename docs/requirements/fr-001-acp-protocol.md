# FR-001: ACP Protocol Support

**Feature Area:** Core Protocol  
**MoSCoW:** Must Have  
**Rationale:** Without ACP compliance the bridge cannot communicate with JetBrains at all. Every item in this document is a hard prerequisite for the product to function.

---

## Requirements

### FR-001.1 — JSON-RPC 2.0 Transport
**Must Have**  
The bridge MUST read newline-delimited JSON-RPC 2.0 messages from `os.Stdin` and write responses to `os.Stdout`.  
- All non-JSON-RPC output (logs, debug info) MUST go to `os.Stderr`.  
- A BOM (Byte Order Mark) MUST NOT be written to `stdout`.  
- No stray newlines or control characters MUST appear on `stdout` outside of valid JSON-RPC.

### FR-001.2 — `initialize` Handshake
**Must Have**  
On receiving `initialize`, the bridge MUST respond with:
```json
{
  "protocolVersion": 1,
  "agentCapabilities": {
    "loadSession": true,
    "supportsModelSelection": true
  },
  "availableModels": ["<model1>", "..."]
}
```
- `availableModels` MUST be populated by querying Docker at startup (`GET /v1/models`).
- If Docker is unreachable during handshake, the bridge MUST return a JSON-RPC error `-32001`.

### FR-001.3 — `session/new`
**Must Have**  
On receiving `session/new`, the bridge MUST:
- Generate a unique `sessionId` (UUID).
- Return `{"sessionId": "<uuid>"}` to the client.
- Initialize an empty conversation history for the session.
- Associate the requested model (from `configOptions` or default) with the session.

### FR-001.4 — `session/prompt`
**Must Have**  
On receiving `session/prompt`, the bridge MUST:
- Retrieve the session's conversation history by `sessionId`.
- Construct an OpenAI-compatible `messages` array and forward to DMR.
- Stream the response back as `session/prompt/chunk` notifications.
- Append both the user prompt and assistant response to session history after completion.

### FR-001.5 — `session/prompt/chunk` Notifications
**Must Have**  
Each SSE `delta.content` token from Docker MUST be forwarded immediately as a `session/prompt/chunk` JSON-RPC notification. Chunks MUST be flushed atomically to prevent IDE timeout.

### FR-001.6 — Unknown Method Handling
**Must Have**  
Any unrecognised JSON-RPC method MUST return error `-32601` (Method Not Found).

### FR-001.7 — `session/load`
**Should Have**  
If `agentCapabilities.loadSession` is advertised, the bridge SHOULD support `session/load` by replaying stored conversation history as `session/update` notifications.

### FR-001.8 — Model Switching
**Should Have**  
The bridge SHOULD support model switching within a session via `session/new` with an updated model ID, rerouting subsequent prompts to the new model without losing session history.

---

## Acceptance Criteria

- `initialize` returns a valid JSON-RPC response within 50ms.
- `session/new` returns a `sessionId` that is unique and stable for the session lifetime.
- `session/prompt` produces one or more `session/prompt/chunk` notifications followed by a final result.
- All messages pass JSON-RPC 2.0 schema validation.
- No non-JSON content appears on `stdout`.
