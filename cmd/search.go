package cmd

import (
	"fmt"
	"os"

	"github.com/devnote-dev/docr/env"
	"github.com/spf13/cobra"
)

var searchCommand = &cobra.Command{
	Use: "search symbol",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			fmt.Fprintln(os.Stderr, "no arguments provided")
			return
		}

		module := ""
		symbol := args[0]
		if len(args) > 1 {
			module = symbol
			// symbol = args[1]
		}

		if module == "" {
			versions, err := env.GetLibraryVersions("crystal")
			if err != nil {
				fmt.Fprintln(os.Stderr, err)
				return
			}

			if len(versions) == 0 {
				fmt.Fprintln(os.Stderr, "latest crystal standard library documentation is not available")
				return
			}

			latest := versions[len(versions)-1]
			lib, err := env.GetLibrary("crystal", latest)
			if err != nil {
				fmt.Fprintln(os.Stderr, err)
				return
			}

			fmt.Printf("%v\n", lib)
		}
	},
}
