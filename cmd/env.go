package cmd

import (
	"fmt"
	"io/fs"
	"os"
	"strings"

	"github.com/devnote-dev/docr/env"
	"github.com/devnote-dev/docr/log"
	"github.com/spf13/cobra"
)

var envCommand = &cobra.Command{
	Use: "env [name]",
	Run: func(cmd *cobra.Command, args []string) {
		log.Configure(cmd)
		if err := exactArgs(1, args); err != nil {
			log.Error(err)
			cmd.HelpFunc()(cmd, args)
			return
		}

		init, _ := cmd.Flags().GetBool("init")
		cache := env.CacheDir()
		lib := env.LibraryDir()

		if init {
			if !exists(cache) {
				if err := os.MkdirAll(cache, fs.FileMode(os.O_CREATE|os.O_RDWR|os.O_TRUNC)); err != nil {
					log.Error("failed to create cache directory")
					log.DebugError(err)
				}
			}

			if !exists(lib) {
				if err := os.MkdirAll(lib, fs.FileMode(os.O_CREATE|os.O_RDWR|os.O_TRUNC)); err != nil {
					log.Error("failed to create library directory")
					log.DebugError(err)
				}
			}
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

		cacheWarn := ""
		if !exists(cache) {
			cacheWarn = " \033[33m(!)\033[0m"
		}

		libWarn := ""
		if !exists(lib) {
			libWarn = " \033[33m(!)\033[0m"
		}

		fmt.Printf("Cache:   %s%s\nLibrary: %s%s\n", cache, cacheWarn, lib, libWarn)
	},
}

func init() {
	envCommand.Flags().Bool("init", false, "create the required directories if missing")
}

func exists(p string) bool {
	if _, err := os.Stat(p); err != nil {
		return false
	}

	return true
}
