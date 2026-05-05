# FR-009: Advanced Features

**Feature Area:** Future Enhancements  
**MoSCoW:** Won't Have (v1.0), Could Have (post-v1.0 roadmap)  
**Rationale:** These features add significant value but are explicitly out of scope for the initial release. They are documented here to inform architectural decisions now (e.g., extensibility hooks) so they can be added later without breaking changes.

---

## Requirements

### FR-009.1 — MCP Tool Calling
**Won't Have (v1.0)**  
Integration with the Model Context Protocol (MCP) to allow local models to invoke tools (filesystem, web search, shell). Requires a separate MCP server subprocess and tool routing layer.

### FR-009.2 — Filesystem Access via MCP
**Won't Have (v1.0)**  
Exposing local filesystem reads/writes to the model via MCP tool definitions.

### FR-009.3 — Auto Model Pull
**Could Have (post-v1.0)**  
If a requested model is not available in Docker, the bridge COULD trigger `docker model pull <model>` and report progress as ACP notifications, rather than immediately returning an error.

**Architectural note:** Ensure the model-not-found error path in v1.0 is extensible to support this without protocol changes.

### FR-009.4 — Enhanced Telemetry
**Could Have (post-v1.0)**  
Relay inference metrics (tokens-per-second, prompt evaluation time, total tokens) to the IDE via custom ACP notifications. Requires agreement on notification namespace.

### FR-009.5 — Session Persistence to Disk
**Could Have (post-v1.0)**  
Persist conversation history to disk (JSON files keyed by `sessionId`) to allow resume across bridge restarts. See also FR-003.8.

### FR-009.6 — Session Sharing Between Clients
**Won't Have**  
Sharing session state between multiple simultaneous IDE clients is explicitly out of scope and will not be designed for.

### FR-009.7 — Multi-Modal Input (Vision)
**Won't Have (v1.0)**  
Image or binary input handling and vision model support. Docker Model Runner support for vision models would need to be validated first.

### FR-009.8 — Multi-Modal Output (Binary Streaming)
**Won't Have (v1.0)**  
Streaming binary data (images, audio) from Docker to the IDE via ACP. Not supported by current ACP spec.

### FR-009.9 — Model Availability Monitoring
**Could Have (post-v1.0)**  
Periodic polling of Docker's model list and notifying the IDE if available models change (e.g., a model was pulled or deleted while a session was active).

### FR-009.10 — Performance Dashboards
**Won't Have**  
A graphical dashboard for inference metrics is out of scope. CLI/log-based metrics are sufficient.

---

## Architectural Guidance for v1.0

The following patterns SHOULD be followed in v1.0 to keep the advanced feature roadmap achievable without breaking changes:

- **Method dispatch table:** Use a map-based JSON-RPC dispatcher so new methods can be registered without modifying `main.go`.
- **Notification bus:** Send internal events through a channel/interface so telemetry notifications can be added as subscribers.
- **Session interface:** Define a `Session` interface rather than a concrete struct so session persistence backends can be swapped in.
- **Model resolver interface:** Abstract model lookup behind an interface so the auto-pull feature can be added as a new implementation.

---

## Acceptance Criteria

- v1.0 ships without any of the Won't Have items implemented.
- The JSON-RPC dispatcher is map-based (extensible without modifying `main.go`).
- The `Session` type is defined as an interface, not a concrete struct.
- The model-not-found error path is isolated behind a model resolver interface.
