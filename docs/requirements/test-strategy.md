# Test Strategy: DMR-ACP-Bridge

**Rationale:** Silent "Agent Disconnected" failures make ACP bridge debugging uniquely difficult. Because the "user" is the IDE's subprocess manager, a layered verification approach is required — automated unit and integration tests catch regressions early; manual IDE diagnostics confirm end-to-end wire compliance.

---

## Tooling

| Tool | Purpose |
|---|---|
| `go test ./...` | Unit and integration tests |
| `go test -race ./...` | Data race detection |
| `io.Pipe` | Simulates IDE stdin/stdout without a real JetBrains process |
| JetBrains Debug Log | Wire traffic inspection for end-to-end verification |

---

## Test Stages

### Stage 1: Unit Tests (Automated)
Cover individual components in isolation using mocked Docker responses and `io.Pipe` for stdio simulation. Each FR and NFR acceptance criterion should have a corresponding unit test.

Run with:
```bash
go test ./...
go test -race ./...
```

**Cross-cutting targets:**
- Zero test failures.
- Zero data races detected by `-race`.
- Code coverage ≥ 80% for `acp_handler.go`, `session.go`, and `stream.go`.

### Stage 2: `io.Pipe` Integration Test (Automated)
Simulate a complete IDE conversation in-process without launching JetBrains:

```go
// Use io.Pipe to connect bridge stdin/stdout to test harness
clientWriter, bridgeReader := io.Pipe()  // test → bridge stdin
bridgeWriter, clientReader := io.Pipe()  // bridge stdout → test
```

Full flow:
1. Send `initialize` → verify response structure and `availableModels`.
2. Send `session/new` → capture and validate `sessionId`.
3. Send `session/prompt` → verify `session/prompt/chunk` notifications arrive in order.
4. Close `stdin` → verify bridge exits with code 0 and no orphaned goroutines.

### Stage 3: Shell Handshake (Manual)
Before any IDE integration, verify the binary produces only valid JSON on `stdout`:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1}}' | ./dmr-acp-bridge
```

**Pass criteria:** Exactly one line of valid JSON on `stdout`. Any "Starting…" or "Connected…" messages must be absent from `stdout` (they may appear on `stderr`).

### Stage 4: JetBrains IDE Wire Diagnostics (Manual)
Once Stages 1–3 pass, verify end-to-end compliance inside the IDE:

1. **Enable logging:** JetBrains → **Help | Diagnostic Tools | Debug Log Settings** → add `#com.intellij.ml.llm.agents:all`.
2. **Run a session:** Trigger `initialize` + a `session/prompt` via the AI Assistant UI.
3. **Inspect logs:**
   ```bash
   tail -f ~/Library/Logs/JetBrains/IntelliJIdea2026.1/idea.log | grep "Agent"
   ```
4. **Pass criteria:** `SENT` and `RECV` blocks present; no "JSON Parse Error" or "Agent Disconnected" entries.

---

## Cross-Cutting Test Cases

These test cases apply across multiple FRs and are documented here rather than in individual requirement files:

### Race Condition Coverage
All session map reads/writes, stream goroutine lifecycles, and I/O flushes MUST pass `go test -race` with no races detected. This validates FR-003 (session management), FR-004 (streaming), and NFR-001 (concurrency).

### Stdout Purity
A test MUST verify that no non-JSON content appears on `stdout` during a full handshake and prompt cycle, including when `--debug` is enabled. This validates FR-001, FR-004, and FR-008 simultaneously.

### Graceful Shutdown Under Load
A test SHOULD send `SIGTERM` while a streaming session is active and verify:
- In-progress Docker request is cancelled.
- All goroutines exit cleanly (verified via `goleak` or manual goroutine count check).
- Process exits with code 0.

This validates FR-005 (signal handling) and NFR-001 (concurrency stability).

### Partial Stream Recovery
A test SHOULD simulate Docker dropping the SSE connection mid-stream and verify:
- Tokens received so far are delivered as `session/prompt/chunk` notifications.
- A `session/prompt/error` notification is sent.
- The session remains usable for subsequent prompts.

This validates FR-004.8 and FR-005.8.
