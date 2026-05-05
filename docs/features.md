# DMR-ACP-Bridge: Features List

## Core Protocol Features

### Agent Client Protocol (ACP) Support
- [x] JSON-RPC 2.0 message dispatch over `stdin`/`stdout`
- [x] `initialize` handshake with capability advertisement
- [x] Session creation and lifecycle management
- [x] Stateful session context (conversation history)
- [x] Model selection and switching
- [x] Prompt streaming with chunked responses

### Docker Model Runner Integration
- [x] OpenAI-compatible Chat Completion API (`POST /v1/chat/completions`)
- [x] Dynamic model discovery via `GET /v1/models`
- [x] Server-Sent Event (SSE) streaming from Docker
- [x] Configurable Docker host and port (default: `localhost:12434`)

### Session Management
- [x] Session UUID generation and tracking
- [x] Conversation history aggregation (stateless → stateful bridge)
- [x] System prompt injection
- [x] Model context per session
- [x] Graceful session cleanup and cancellation

---

## Streaming & I/O Features

### Stream Handling
- [x] Server-Sent Event (SSE) parsing from Docker
- [x] Real-time chunk buffering and forwarding
- [x] Atomic message flushing to prevent JetBrains timeout
- [x] Non-blocking I/O pipeline
- [x] Graceful stream termination on `[DONE]` sentinel

### Output Sanitization
- [x] Strict `stdout` JSON-RPC enforcement (no log leaks)
- [x] All telemetry/debug logs directed to `stderr`
- [x] BOM (Byte Order Mark) prevention
- [x] No stray newlines or control characters on `stdout`

### Buffering & Flushing
- [x] Explicit `bufio.Writer.Flush()` after each JSON-RPC message
- [x] Configurable buffer size for streaming chunks
- [x] Connection keep-alive handling

---

## Error Handling & Resilience

### Error Mapping
- [x] Docker unreachable → JSON-RPC error `-32001` ("Docker Model Runner not detected")
- [x] Model not found → JSON-RPC error `-32602` ("Model not found. Please run 'docker pull'.")
- [x] Inference timeout → JSON-RPC error `-32000` ("Local inference timed out.")
- [x] Malformed JSON-RPC → JSON-RPC error `-32700` (Parse error)
- [x] Unknown methods → JSON-RPC error `-32601` (Method not found)

### Graceful Degradation
- [x] Timeout handling for stuck inferences
- [x] Connection retry with exponential backoff
- [x] Partial message recovery (don't drop partial chunks)
- [x] Orphaned stream cleanup on client disconnect

### Signal Handling
- [x] `SIGINT` (`Ctrl+C`) graceful shutdown
- [x] `SIGTERM` daemon-mode termination
- [x] Active inference cancellation on shutdown
- [x] Resource cleanup (close HTTP clients, file descriptors)
- [x] Exit code 0 on clean shutdown, non-zero on error

---

## Configuration & Deployment

### CLI Configuration
- [x] `--docker-host` flag (default: `http://localhost:12434`)
- [x] `--debug` flag for verbose logging to `stderr`
- [x] `--timeout` flag for inference timeout threshold (default: 60s)
- [x] `--port` flag for Docker Model Runner port override
- [x] Version flag (`--version`)
- [x] Help flag (`--help`)

### Environment Variables
- [x] `DMR_HOST` (override `--docker-host`)
- [x] `DMR_TIMEOUT` (override `--timeout`)
- [x] `DEBUG` / `LOG_LEVEL` for logging control
- [x] `GOMAXPROCS` for Go runtime tuning

### IDE Integration
- [x] Static binary (no Go runtime required)
- [x] Cross-platform support (Linux, macOS, Windows)
- [x] Registration via `acp.json` configuration
- [x] Zero external dependencies (except Docker)

---

## Performance & Optimization

### Performance Targets
- [x] Binary size < 15MB
- [x] Handshake latency < 50ms
- [x] Streaming overhead < 50ms per token
- [x] Memory footprint < 20MB RSS
- [x] Support multiple concurrent sessions

### Resource Efficiency
- [x] Connection pooling to Docker
- [x] Efficient message routing (no unnecessary copies)
- [x] Streaming response handling (no full response buffering)
- [x] Lazy session initialization (only on first prompt)

### Concurrency
- [x] Multiple simultaneous streaming sessions
- [x] Non-blocking request dispatch
- [x] Thread-safe session map
- [x] Graceful multiplexing of multiple IDE clients (if applicable)

---

## Testing & Verification

### Unit Testing
- [x] Handshake validation (initialize → correct response)
- [x] Error mapping verification
- [x] Stream parsing (SSE → ACP chunks)
- [x] Session management (create, switch, cleanup)
- [x] Mock Docker responses

### Integration Testing
- [x] Shell handshake test (manual JSON-RPC input)
- [x] `io.Pipe` simulation of IDE interaction
- [x] Full conversation flow (initialize → session/new → session/prompt → streaming)
- [x] Graceful exit on `stdin` close
- [x] Orphaned process cleanup verification

### IDE Diagnostics
- [x] JetBrains debug log verification (`#com.intellij.ml.llm.agents:all`)
- [x] Wire traffic inspection (SENT/RECV blocks)
- [x] JSON Parse Error detection
- [x] Agent Disconnected error analysis

### Error State Testing
- [x] DMR offline handling
- [x] Model not found handling
- [x] Timeout handling
- [x] Partial response handling
- [x] Stream interruption recovery

---

## Observability & Debugging

### Logging
- [x] Debug-level logs to `stderr`
- [x] Request/response logging (JSON-RPC)
- [x] Stream event logging
- [x] Error and stack trace logging
- [x] Configurable log levels (debug, info, warn, error)

### Metrics
- [x] Request count and latency
- [x] Active session count
- [x] Memory usage tracking
- [x] Docker connection status
- [x] Stream chunk count and bytes

### Tracing
- [x] Request trace IDs (for correlation)
- [x] Session context logging
- [x] Stream event timing
- [x] Error origin tracing

---

## Advanced Features (Future)

### Model Context Protocol (MCP) Integration
- [ ] MCP tool calling support
- [ ] Filesystem access via MCP
- [ ] Web search via MCP
- [ ] External tool invocation

### Enhanced Telemetry
- [ ] Token-per-second metrics
- [ ] Prompt evaluation time tracking
- [ ] Custom metrics via ACP notifications
- [ ] Performance dashboards

### Auto Model Management
- [ ] `docker model pull` triggering from bridge
- [ ] Model availability monitoring
- [ ] Model preloading on startup
- [ ] Model eviction/cleanup handling

### Session Persistence
- [ ] Session export/import
- [ ] Conversation history saved to disk
- [ ] Resume interrupted sessions
- [ ] Session sharing between clients

### Multi-Modal Support
- [ ] Image input handling
- [ ] Vision model support
- [ ] Binary data streaming
- [ ] Multimodal response handling

---

## Security & Compliance

### Input Validation
- [x] JSON-RPC message validation
- [x] Session ID validation
- [x] Model name sanitization
- [x] Prompt size limits

### Output Security
- [x] No sensitive data logging (keys, tokens)
- [x] Sanitized error messages to client
- [x] No environment variable leakage
- [x] Safe shutdown (no partial state exposure)

### Docker Security
- [x] Docker host validation (localhost-only by default)
- [x] No arbitrary command execution
- [x] Timeout to prevent resource exhaustion
- [x] Rate limiting on requests

---

## Documentation & Examples

### Documentation
- [x] README with quick start
- [x] Architecture diagram
- [x] Protocol flow diagrams
- [x] Deployment guide
- [x] Troubleshooting guide

### Code Examples
- [x] Minimal ACP server example (from `coder/acp-go-sdk`)
- [x] Session management example
- [x] Streaming example
- [x] Error handling example
- [x] Configuration example

### Configuration Examples
- [x] `acp.json` template
- [x] Environment variable examples
- [x] Docker Compose setup example
- [x] Systemd service file example

---

## Status Legend
- `[x]` Planned or implemented
- `[ ]` Future/optional
