package cmd

import _ "embed"

var (
	//go:embed VERSION
	Version string
	Build   string
)
