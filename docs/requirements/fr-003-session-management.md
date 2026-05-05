# FR-003: Session Management

**Feature Area:** Session Lifecycle  
**MoSCoW:** Must Have  
**Rationale:** ACP is a stateful protocol; the bridge must maintain per-session context across a stateless Docker backend.

---

## Requirements

### FR-003.1 — Session ID Generation
**Must Have**  
The bridge MUST generate a unique `sessionId` (UUID v4) when processing `session/new` and return it to the client. The client is responsible for using this ID in subsequent requests.

### FR-003.2 — Conversation History
**Must Have**  
The bridge MUST maintain an in-memory ordered list of `{role, content}` pairs per session. On each `session/prompt`, the full history MUST be sent to Docker as the `messages` array.

### FR-003.3 — System Prompt Injection
**Must Have**  
If a system prompt is provided at session creation or via `session/new`, it MUST be prepended as a `{"role": "system", ...}` message in every subsequent inference request to Docker.

### FR-003.4 — Model Context Per Session
**Must Have**  
Each session MUST track which model it is configured to use. Inference requests MUST use the session's model, not a global default.

### FR-003.5 — Graceful Session Cleanup
**Must Have**  
When a session is cancelled or the client disconnects, the bridge MUST:
- Cancel any in-progress inference request to Docker.
- Release all resources (channels, goroutines) associated with the session.
- Remove the session from the session map.

### FR-003.6 — Thread-Safe Session Map
**Must Have**  
The session map MUST be protected by a `sync.RWMutex` (or equivalent) to allow safe concurrent reads and writes from multiple goroutines.

### FR-003.7 — Session Load / Resume
**Should Have**  
The bridge SHOULD support `session/load`, replaying the stored conversation history to the client as `session/update` notifications, enabling the IDE to resume a prior conversation.

### FR-003.8 — Session Persistence to Disk
**Could Have**  
The bridge COULD persist session history to disk (e.g., JSON files keyed by `sessionId`) to survive process restarts, enabling true resume across bridge restarts.

### FR-003.9 — Session Sharing
**Won't Have**  
Session sharing between multiple clients is explicitly out of scope for v1.0.

---

## Acceptance Criteria

- Two concurrent sessions with different models produce independent responses.
- History is correctly accumulated: the third prompt receives the full prior context.
- Cancelling a session while streaming terminates the Docker request and releases all goroutines.
- Session map read/write under concurrent load produces no data races (verified with `go test -race`).
