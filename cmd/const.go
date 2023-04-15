package cmd

import _ "embed"

var (
	//go:embed VERSION
	Version string
	Build   = "dev"
	Date    = "unknown"
)
