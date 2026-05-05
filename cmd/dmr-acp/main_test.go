package main

import (
	"testing"

	_ "github.com/coder/acp-go-sdk"
	"github.com/stretchr/testify/assert"
)

func TestSkip(t *testing.T) {
	assert.True(t, true, "TODO: Implement bridge logic")
	t.Skip("TODO: Implement bridge logic")
}
