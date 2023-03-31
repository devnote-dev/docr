package cmd

import (
	"fmt"
	"io/fs"
	"os"
	"strings"

	"github.com/devnote-dev/docr/env"
	"github.com/spf13/cobra"
)

var envCommand = &cobra.Command{
	Use: "env [name] [options]",
	Run: func(cmd *cobra.Command, args []string) {
		init, _ := cmd.Flags().GetBool("init")
		cache := env.CacheDir()
		lib := env.LibDir()

		if init {
			if !exists(cache) {
				if os.MkdirAll(cache, fs.FileMode(os.O_CREATE|os.O_RDWR|os.O_TRUNC)) != nil {
					fmt.Fprintln(os.Stderr, "failed to create cache directory")
				}

				fmt.Printf("Cache: %s\n", cache)
			}

			if !exists(lib) {
				if os.MkdirAll(lib, fs.FileMode(os.O_CREATE|os.O_RDWR|os.O_TRUNC)) != nil {
					fmt.Fprintln(os.Stderr, "failed to create library directory")
				}

				fmt.Printf("Library: %s\n", lib)
			}

			return
		}

		if len(args) > 0 {
			name := args[0]
			switch strings.ToLower(name) {
			case "cache":
				fmt.Println(cache)
			case "lib":
				fallthrough
			case "library":
				fallthrough
			case "libraries":
				fmt.Println(lib)
			}

			return
		}

		fmt.Printf("Cache: %s\nLibrary: %s\n", cache, lib)
	},
}

func exists(p string) bool {
	if _, err := os.Stat(p); err != nil {
		return false
	}

	return true
}
