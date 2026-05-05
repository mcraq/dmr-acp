# DMR-ACP-Bridge: Requirements Index

## Functional Requirements (FR)

| ID | Feature Area | MoSCoW | Document |
|---|---|---|---|
| FR-001 | ACP Protocol Support | **Must Have** | [fr-001-acp-protocol.md](fr-001-acp-protocol.md) |
| FR-002 | Docker Model Runner Integration | **Must Have** | [fr-002-docker-integration.md](fr-002-docker-integration.md) |
| FR-003 | Session Management | **Must Have** | [fr-003-session-management.md](fr-003-session-management.md) |
| FR-004 | Streaming & I/O | **Must Have** | [fr-004-streaming-io.md](fr-004-streaming-io.md) |
| FR-005 | Error Handling & Resilience | **Must Have** | [fr-005-error-handling.md](fr-005-error-handling.md) |
| FR-006 | Configuration & Deployment | **Must Have** | [fr-006-configuration.md](fr-006-configuration.md) |
| FR-007 | Security & Compliance | **Must Have** | [fr-007-security.md](fr-007-security.md) |
| FR-008 | Observability & Debugging | **Must Have** | [fr-008-observability.md](fr-008-observability.md) |
| FR-009 | Advanced Features (Roadmap) | **Won't Have (v1.0)** | [fr-009-advanced-features.md](fr-009-advanced-features.md) |

## Non-Functional Requirements (NFR)

| ID | Feature Area | MoSCoW | Document |
|---|---|---|---|
| NFR-001 | Performance & Scalability | **Must Have** | [nfr-001-performance.md](nfr-001-performance.md) |
| NFR-002 | Portability & Deployment Constraints | **Must Have** | [nfr-002-portability.md](nfr-002-portability.md) |
| NFR-003 | Security Constraints | **Should Have** | [nfr-003-security-constraints.md](nfr-003-security-constraints.md) |
| NFR-004 | Observability Quality Attributes | **Must Have** | [nfr-004-observability-quality.md](nfr-004-observability-quality.md) |

## Test Strategy

| Document | Purpose |
|---|---|
| [test-strategy.md](test-strategy.md) | Staged test approach, cross-cutting test cases, tooling, coverage targets |

---

## MoSCoW Legend

| Priority | Meaning |
|---|---|
| **Must Have** | Non-negotiable. The product does not work without this. |
| **Should Have** | Important, but can be deferred from first release if necessary. |
| **Could Have** | Desirable but low impact if omitted. |
| **Won't Have** | Explicitly out of scope for v1.0. Documented for future planning. |

---

## Classification Guide

| Type | Definition |
|---|---|
| **FR** | What the system must DO — observable behaviours, methods handled, data produced. |
| **NFR** | Quality attributes and constraints — latency budgets, memory limits, binary size, concurrency safety, portability, security constraints. These are acceptance criteria *on* FRs rather than standalone behaviours. |
| **Test Strategy** | Cross-cutting test approach, tooling, and staged verification. Per-requirement acceptance criteria live in the FR/NFR documents themselves. |

---

## v1.0 Scope (Must + Should Have)

**Must Have (FR-001 to FR-008, NFR-001, NFR-002, NFR-004):**
- ACP protocol compliance (handshake, sessions, streaming)
- Docker Model Runner integration
- Full error mapping and signal handling
- Static binary deployment, no Go runtime dependency
- Security hardening (input validation, no credential leakage)
- Performance targets (< 50ms latency, < 20MB RSS, < 15MB binary)
- Structured debug logging with session IDs
- Configurable log levels
- Unit and integration test suite

**Should Have (NFR-003):**
- Localhost-only Docker host restriction
- Prompt size limits, timeout as resource guard
- Connection pooling, retry with backoff
- Cross-platform builds

**Post-v1.0 (FR-009):**
- MCP tool calling
- Auto model pull
- Session persistence
- Enhanced telemetry

