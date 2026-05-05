package main

import (
	"flag"
	"fmt"
	"os"
)

var (
	version    = "0.1.0"
	dockerHost = flag.String("docker-host", "http://localhost:12434", "Docker Model Runner endpoint")
	timeout    = flag.Int("timeout", 60, "Inference timeout in seconds")
	debug      = flag.Bool("debug", false, "Enable debug logging to stderr")
)

func main() {
	flag.Parse()

	if len(flag.Args()) > 0 && flag.Args()[0] == "version" {
		fmt.Printf("dmr-acp v%s\n", version)
		os.Exit(0)
	}

	fmt.Fprintf(os.Stderr, "dmr-acp v%s starting\n", version)
	fmt.Fprintf(os.Stderr, "Docker host: %s\n", *dockerHost)
	fmt.Fprintf(os.Stderr, "Timeout: %ds\n", *timeout)
	fmt.Fprintf(os.Stderr, "Debug: %v\n", *debug)

	// TODO: Implement bridge logic
	select {}
}
