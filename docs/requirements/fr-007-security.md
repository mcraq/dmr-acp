# FR-007: Security & Compliance

**Feature Area:** Security  
**MoSCoW:** Must Have (input validation, no credential leakage)  
**Rationale:** The bridge runs as a trusted subprocess. It must not expose sensitive data, execute arbitrary commands, or be exploitable via malformed input.

---

## Requirements

### FR-007.1 — JSON-RPC Input Validation
**Must Have**  
All incoming JSON-RPC messages MUST be validated for schema conformance before processing. Invalid messages MUST return `-32700` (Parse error) or `-32600` (Invalid Request) without panicking.

### FR-007.2 — Session ID Validation
**Must Have**  
`sessionId` values provided by the client in `session/prompt` and `session/load` MUST be validated against the session map. An unknown `sessionId` MUST return a JSON-RPC error, not crash or leak data from another session.

### FR-007.3 — Model Name Sanitization
**Must Have**  
Model names extracted from requests MUST be sanitised before being included in Docker API calls. Characters outside `[a-zA-Z0-9:._-]` MUST be rejected with error `-32602`.

### FR-007.4 — No Credential Logging
**Must Have**  
Sensitive data (API keys, tokens, environment variables containing secrets) MUST NOT be written to `stderr` or `stdout` at any log level.

### FR-007.5 — No Arbitrary Command Execution
**Must Have**  
The bridge MUST NOT execute any shell commands or subprocesses derived from user input. Docker interaction MUST be via HTTP only.

### FR-007.6 — Safe Shutdown (No Partial State Exposure)
**Must Have**  
On shutdown, in-progress session data MUST NOT be written to disk or exposed via any channel. The bridge MUST terminate cleanly without leaving partial state that a subsequent process could read.

---

## Acceptance Criteria

- Sending a `session/prompt` with an unknown `sessionId` returns a JSON-RPC error (not a panic).
- A model name containing `; rm -rf /` is rejected with `-32602` before reaching Docker.
- Running with `--debug` does not log any content from `DMR_HOST` or request bodies containing `password` or `token`.
