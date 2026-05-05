# dmr-acp

Docker Model Runner to Agent Client Protocol (ACP) bridge for JetBrains AI Assistant.

## Project Status

**Pre-release (v0.1.0)** — Design and architecture phase. See [docs/design.md](docs/design.md) for detailed specification.

## Quick Start

### Prerequisites
- Go 1.22+
- Docker with a Model Runner endpoint (default: `http://localhost:12434`)

### Build
```bash
make build
```

### Run
```bash
./dmr-acp --docker-host http://localhost:12434 --debug
```

### Test
```bash
make test
make test-race
```

## Documentation

- [Design Specification](docs/design.md) — Architecture, protocol, implementation strategy
- [Features](docs/features.md) — Checklist of planned capabilities
- [Requirements](docs/requirements/) — Detailed FR/NFR/test requirements

## Development

Generate mocks:
```bash
make mocks
```

See `Makefile` for more targets.

## License

TBD
