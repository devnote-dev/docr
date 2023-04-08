package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/devnote-dev/docr/env"
	"github.com/spf13/cobra"
)

var indexCommand = &cobra.Command{
	Use: "index command [arguments] [options]",
	Run: func(*cobra.Command, []string) {},
}

var indexListCommand = &cobra.Command{
	Use: "list [options]",
	Run: func(*cobra.Command, []string) {
		libraries, err := env.GetLibraries()
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}

		if len(libraries) == 0 {
			return
		}

		builder := strings.Builder{}
		for name, versions := range libraries {
			builder.WriteString(name)
			builder.WriteString("\n|\n")

			if len(versions) > 1 {
				for _, v := range versions[:1] {
					builder.WriteString("|———— v")
					builder.WriteString(strings.TrimSuffix(v, ".json"))
					builder.WriteRune('\n')
				}
			}

			builder.WriteString("'———— v")
			builder.WriteString(strings.TrimSuffix(versions[len(versions)-1], ".json"))
			builder.WriteRune('\n')
		}

		fmt.Println(builder.String())
	},
}

var indexGetCommand = &cobra.Command{
	Use: "get source",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			return
		}

		src := args[0]
		cwd, _ := os.Getwd()

		if src == "." {
			if _, err := os.Stat(filepath.Join(cwd, "shard.yml")); err != nil {
				fmt.Fprintln(os.Stderr, "shard.yml file not found")
				// TODO:
				// load shard.yml
				// build docs
			}
		}

		// TODO:
		// attempt to request shard source
		// load shard.yml
		// build docs
		// extract and cache
	},
}

func init() {
	indexCommand.AddCommand(indexListCommand)
	indexCommand.AddCommand(indexGetCommand)
}
