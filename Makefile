.PHONY: all build test-unit generate-mocks clean-mocks toolset snapshot release clean help

all: build test-unit snapshot

# Toolset setup
bin/toolset:
	@mkdir -p bin
	@GOBIN=$(PWD)/bin go install github.com/kazhuravlev/toolset/cmd/toolset@v0.42.0
	@./bin/toolset sync

.PHONY: toolset
toolset: bin/toolset

build: bin
	go build -o bin/dmr-acp ./cmd/dmr-acp

bin:
	mkdir -p bin

test-unit: generate-mocks
	go test -race ./...

generate-mocks: bin/toolset
	./bin/toolset run mockery

clean-mocks:
	find . -name mock_test.go -delete

snapshot:
	goreleaser build --snapshot --clean

release:
	goreleaser release --clean

help:
	@echo "dmr-acp makefile targets:"
	@echo "  make all            - Build, test, and snapshot (default)"
	@echo "  make build          - Build the binary"
	@echo "  make test-unit      - Run unit tests with race detection"
	@echo "  make generate-mocks - Generate mocks with mockery"
	@echo "  make clean-mocks    - Clean generated mocks"
	@echo "  make snapshot       - Build snapshot release with goreleaser"
	@echo "  make release        - Build and publish release with goreleaser"
	@echo "  make toolset        - Install and sync toolset"
	@echo "  make clean          - Clean build artifacts"

clean:
	rm -rf bin/
	rm -rf dist/
