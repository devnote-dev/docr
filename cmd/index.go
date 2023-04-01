package cmd

import (
	"fmt"
	"os"
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
	Run: func(cmd *cobra.Command, args []string) {
		libraries, err := env.GetLibraries()
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}

		builder := strings.Builder{}
		for name, versions := range libraries {
			builder.WriteString(name)
			builder.WriteRune('\n')

			for _, v := range versions {
				builder.WriteRune('\t')
				builder.WriteString(strings.TrimSuffix(v, ".json"))
			}
		}

		fmt.Println(builder.String())
	},
}

func init() {
	indexCommand.AddCommand(indexListCommand)
}
