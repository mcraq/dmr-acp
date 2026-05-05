# FR-006: Configuration & Deployment

**Feature Area:** Configuration  
**MoSCoW:** Must Have (core flags), Should Have (env vars)  
**Rationale:** The binary must be deployable without a Go runtime and configurable by the IDE's `acp.json` without code changes.

---

## Requirements

### FR-006.1 — `--docker-host` Flag
**Must Have**  
The Docker Model Runner base URL MUST be configurable via `--docker-host`. Default: `http://localhost:12434`.

### FR-006.2 — `--timeout` Flag
**Must Have**  
Inference timeout MUST be configurable via `--timeout` (in seconds). Default: `60`.

### FR-006.3 — `--debug` Flag
**Must Have**  
When `--debug` is set, verbose request/response logging MUST be written to `stderr`. When not set, only errors and warnings MUST be logged.

### FR-006.4 — `--version` and `--help`
**Must Have**  
The binary MUST respond to `--version` (print semver and exit 0) and `--help` (print usage and exit 0).

### FR-006.5 — `DMR_HOST` Environment Variable
**Should Have**  
`DMR_HOST` SHOULD override `--docker-host`, enabling configuration without modifying `acp.json`.

### FR-006.6 — `DMR_TIMEOUT` Environment Variable
**Should Have**  
`DMR_TIMEOUT` SHOULD override `--timeout`.

### FR-006.7 — `LOG_LEVEL` Environment Variable
**Should Have**  
`LOG_LEVEL` (values: `debug`, `info`, `warn`, `error`) SHOULD control log verbosity independently of `--debug`.

### FR-006.8 — `acp.json` Registration
**Must Have**  
The bridge MUST be registerable in JetBrains via `acp.json`:
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

### FR-006.9 — `--port` Shorthand Flag
**Could Have**  
A `--port` flag COULD be provided as a shorthand for overriding only the port component of the Docker host, for users who only change the port.

---

## Acceptance Criteria

- Running `./dmr-acp-bridge --version` prints a semver string and exits 0.
- `DMR_HOST=http://127.0.0.1:9999 ./dmr-acp-bridge` connects to the specified host.
- `acp.json` registration results in JetBrains launching the bridge as a subprocess.
