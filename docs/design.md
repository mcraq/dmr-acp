# Unified Project Plan: DMR-ACP-Bridge
**Project:** Docker Model Runner to Agent Client Protocol (ACP) Bridge  
**Language:** Go (Golang)  
**Target:** JetBrains AI Assistant  
**Version:** 1.0.0  
**Foundation:** [`coder/acp-go-sdk`](https://github.com/coder/acp-go-sdk)

---

## 1. Executive Summary
The **DMR-ACP-Bridge** is a high-performance gateway written in Go that translates the **Agent Client Protocol (ACP)** used by modern AI IDE clients into the **OpenAI REST API** used by the **Docker Model Runner (DMR)**. It enables a "Bring Your Own Model" (BYOM) workflow within JetBrains AI Assistant using locally hosted Docker containers.

The bridge runs as a sidecar subprocess managed by the host IDE, utilizing `stdin/stdout` for JSON-RPC communication and HTTP for model interaction.

---

## 2. Design & Architecture

### 2.1 System Overview
**Northbound:** JSON-RPC 2.0 (ACP) over standard streams (`stdin`/`stdout`).  
**Southbound:** OpenAI-compatible REST API (DMR) via HTTP localhost (e.g., `http://localhost:12434/v1/chat/completions`).

### 2.2 Component Stack
* **ACP Handler:** Stateful management of JSON-RPC 2.0 requests using [`coder/acp-go-sdk`](https://github.com/coder/acp-go-sdk).
* **Model Interrogator:** Queries Docker for available GGUF/model files via `GET /v1/models`.
* **Session Router:** Maps IDE session IDs to DMR inference contexts; aggregates history for stateless DMR.
* **Inference Proxy:** Converts ACP `session/prompt` requests into OpenAI-compatible Chat Completion requests.
* **Stream Transcoder:** Pipelines Server-Sent Events (SSE) from Docker back to the IDE as ACP `session/prompt/chunk` notifications.

### 2.3 Go Dependencies
* **[`coder/acp-go-sdk`](https://github.com/coder/acp-go-sdk):** Official Go SDK for ACP protocol. Provides typed requests/responses, stdio handling, and examples.
* **Standard library:** `bufio`, `encoding/json`, `net/http`, `io`, `sync` for I/O, marshalling, HTTP, and concurrency.

---

## 3. Protocol Implementation

### 3.1 The `initialize` Handshake
On startup, the bridge receives an `initialize` request and must respond with capabilities and available models.

**Example Request:**
```
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1}}
```

**Example Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": 1,
    "agentCapabilities": {
        "loadSession": true,
        "supportsModelSelection": true
    },
    "availableModels": ["llama3.1:8b", "mistral-nemo", "phi-3-medium"]
  }
}
```

**Implementation note:** Use the `coder/acp-go-sdk` to handle JSON-RPC marshalling; fetch available models via `GET http://localhost:12434/v1/models` during handshake.

### 3.2 Session Management
* **Session ID Generation:** When the IDE sends `session/new` with `cwd` and `mcpServers`, the bridge generates a unique `sessionId` and returns it. Per ACP spec, the server (bridge) is responsible for session ID generation.
* **Stateful Mapping:** Bridge tracks `sessionId` to maintain conversation history per session; DMR is stateless.
* **Prompt Handling:** Intercepts `session/prompt` with the client-provided `sessionId`, aggregates prior messages from that session into OpenAI `messages` array, sends to DMR.
* **Model Switching:** When user selects a new model in the IDE, intercepts `session/new` to update model routing for subsequent prompts in that session.
* **Session Loading:** If the IDE requests `session/load` (supported via `loadSession` capability), replays the session's conversation history as `session/update` notifications.

---

## 4. Implementation Strategy

### 4.1 File Organization
```
dmr-acp-bridge/
 main.go              # Entry point, stdio setup, signal handling
 acp_handler.go       # JSON-RPC dispatch using coder/acp-go-sdk
 session.go           # Session state, history aggregation
 docker_client.go     # HTTP client for Docker Model Runner
 stream.go            # SSE parsing, ACP chunk wrapping
 config.go            # CLI flags, Docker host/port
 main_test.go         # Integration tests (io.Pipe for stdio simulation)
```

### 4.2 Key Implementation Details

#### 4.2.1 I/O & Logging
* **Northbound:** Use `coder/acp-go-sdk` for JSON-RPC over `os.Stdin`/`os.Stdout`.
* **Logging:** All debug/telemetry logs to `os.Stderr` only. **Strict enforcement:** Any non-JSON-RPC data on `os.Stdout` breaks the IDE integration.
* **Buffering:** Call `bufio.NewWriter(os.Stdout).Flush()` after every JSON-RPC message to prevent timeout on partial buffers.

#### 4.2.2 Error Mapping
| Error Type | ACP Error Code | User Message |
| :--- | :--- | :--- |
| Docker unreachable | -32001 | "Docker Model Runner not detected on :12434" |
| Model not found | -32602 | "Model not found. Please run 'docker pull <model>'." |
| Inference timeout | -32000 | "Local inference timed out." |

#### 4.2.3 Streaming Pipeline
1. Receive `text/event-stream` (SSE) from Docker (`POST /v1/chat/completions` with `stream: true`).
2. Parse each `data: {...}` chunk, extract `delta.content`.
3. Wrap in ACP `session/prompt/chunk` notification.
4. Flush immediately to `stdout` (non-blocking).
5. On final `data: [DONE]`, close the notification stream.

#### 4.2.4 Signal Handling
* Catch `os.Interrupt` (`SIGINT`) and `syscall.SIGTERM` to:
  - Stop any active Docker inference.
  - Close all open session streams gracefully.
  - Exit with code 0.

### 4.3 Implementation Checklist
* [ ] Initialize Go module and add `coder/acp-go-sdk` as dependency.
* [ ] Implement `main.go` with stdio setup using SDK examples.
* [ ] Build `acp_handler.go` to dispatch JSON-RPC methods (initialize, session/new, session/prompt).
* [ ] Build `docker_client.go` to query models and send chat completion requests.
* [ ] Implement `session.go` for stateful context management.
* [ ] Implement `stream.go` for SSE → ACP chunk conversion.
* [ ] Add signal handling for graceful shutdown.
* [ ] Verify **no non-JSON output on stdout** (all logs to stderr).
* [ ] Implement buffering with explicit `Flush()` calls.
* [ ] Static linking: ensure binary is platform-independent.

---

## 5. Testing & Verification

Verification of an ACP bridge is unique because the "user" is the IDE's subprocess manager. Failure manifests as a silent "Agent Disconnected" error, making these steps critical.

### 5.1 Stage 1: Protocol Compliance (Manual)
Before integrating with JetBrains, verify the binary doesn't pollute `stdout`.

1. **The "No-Log" Test:** Run the bridge and send a manual handshake.
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1}}' | ./dmr-acp-bridge
   ```
2. **Success Criteria:** Output must be **exactly** one line of valid JSON. Any "Starting server..." or "Connected to Docker" messages must be on `os.Stderr`.

### 5.2 Stage 2: Mocked Integration (Automated)
Use Go's `io.Pipe` to simulate the IDE. Test the full state machine:

| Test Case | Method | Expected Result |
| :--- | :--- | :--- |
| **DMR Discovery** | Mock `GET /v1/models` response | `initialize` result contains those specific model names. |
| **Handshake** | Send `initialize` | Response `protocolVersion == 1`, capabilities advertised. |
| **Session Create** | Send `session/new` | Bridge creates internal session UUID. |
| **Prompt + Streaming** | Send `session/prompt` with messages | Multiple `session/prompt/chunk` notifications received in order. |
| **Graceful Exit** | Close `stdin` | Go process exits with code 0 (no orphaned Docker processes). |

**Test Implementation:**
```go
// Use io.Pipe to simulate stdin/stdout without launching actual IDE
//   reader, writer := io.Pipe()
// Send initialize request via writer
// Read response from reader
// Verify JSON structure and content
```

### 5.3 Stage 3: JetBrains IDE Diagnostics
Once Stages 1 and 2 pass, verify wire traffic inside the IDE.

1. **Enable Logging:** Open JetBrains → **Help | Diagnostic Tools | Debug Log Settings**.
2. **Add Category:** Enter `#com.intellij.ml.llm.agents:all`.
3. **Monitor Logs:**
   ```bash
   tail -f ~/Library/Logs/JetBrains/IntelliJIdea2026.1/idea.log | grep "Agent"
   ```
4. **Verification:** Look for `SENT` and `RECV` blocks. If you see `RECV` followed by a "JSON Parse Error," the binary is likely sending a BOM (Byte Order Mark) or stray newline.

### 5.4 Stage 4: Error State Handling
Verify how the bridge handles Docker Model Runner failures:
* **DMR Offline:** The bridge returns a JSON-RPC error `-32001`.
* **Model Not Found:** If a user selects a model just deleted from Docker, the bridge sends a `session/prompt/error` notification rather than hanging.
* **Timeout:** Long-running inference terminates gracefully after timeout threshold.

---

## 6. Deployment

### 6.1 Performance Targets
* **Binary Size:** < 15MB (static build).
* **Handshake Latency:** < 50ms (time from `initialize` request to response).
* **Streaming Overhead:** < 50ms per token.
* **Memory Footprint:** < 20MB RSS under typical load.
* **Stability:** 100% success rate on `SIGTERM` cleanup.
* **Concurrency:** Support multiple simultaneous streaming sessions (limited by DMR VRAM).

### 6.2 Configuration (`acp.json`)
User modifies their JetBrains/IDE ACP configuration:

```json
{
  "agent_servers": {
    "Docker Local": {
      "command": "/usr/local/bin/dmr-acp-bridge",
      "args": ["--docker-host", "http://localhost:12434"],
      "env": { "DEBUG": "true" }
    }
  }
}
```

### 6.3 Installation
* Build statically: `CGO_ENABLED=0 go build -ldflags '-s -w' -o dmr-acp-bridge`
* Verify no dynamic dependencies: `ldd ./dmr-acp-bridge` (should fail or show only kernel libs)
* Install to `/usr/local/bin` or system PATH
* User updates `acp.json` and restarts JetBrains

---

## 7. Future Roadmap
* **MCP Integration:** Implement Model Context Protocol to allow local models to call external tools (filesystem, web search).
* **Telemetry Bridge:** Relay detailed inference metrics (tokens/sec, prompt eval time) to IDE via custom notifications.
* **OOB Model Pulling:** Trigger `docker model pull` from bridge if requested model is missing, showing progress via ACP notifications.

---

## 8. References
* **ACP SDK:** https://github.com/coder/acp-go-sdk
* **ACP Protocol:** https://agentclientprotocol.com
* **Docker Model Runner:** Local OpenAI-compatible API (e.g., `http://localhost:12434/v1/chat/completions`)
* **Go pkg.go.dev:** https://pkg.go.dev/github.com/coder/acp-go-sdk
