package cmd

import (
	"fmt"
	"strings"

	"github.com/devnote-dev/docr/env"
	"github.com/devnote-dev/docr/log"
	"github.com/spf13/cobra"
)

var listCommand = &cobra.Command{
	Use:   "list",
	Short: "lists imported libraries",
	Long:  "Lists imported libraries, including their versions.",
	Run: func(cmd *cobra.Command, args []string) {
		log.Configure(cmd)
		if err := noArgs(args); err != nil {
			log.Error("%v\n", err)
			cmd.Help()
			return
		}

		libraries, err := env.GetLibraries()
		if err != nil {
			log.Error("failed to get libraries:")
			log.Error(err)
			return
		}

		if len(libraries) == 0 {
			log.Error("no libraries have been installed")
			return
		}

		builder := strings.Builder{}
		for name, versions := range libraries {
			builder.WriteString(name)
			for _, v := range versions {
				builder.WriteString("\n• ")
				if c := v[0]; c >= '0' && c <= '9' {
					builder.WriteRune('v')
				}
				builder.WriteString(v)
			}
			builder.WriteString("\n\n")
		}

		fmt.Println(strings.TrimSuffix(builder.String(), "\n\n"))
	},
}
