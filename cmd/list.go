package cmd

import (
	"fmt"
	"strings"

	"github.com/devnote-dev/docr/env"
	"github.com/devnote-dev/docr/log"
	"github.com/spf13/cobra"
)

var listCommand = &cobra.Command{
	Use: "list [options]",
	Run: func(cmd *cobra.Command, _ []string) {
		log.Configure(cmd)
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
			builder.WriteString("\n|\n")

			if len(versions) > 1 {
				for _, v := range versions[:1] {
					fmt.Fprintf(&builder, "|———— v%s\n", v)
				}
			}

			fmt.Fprintf(&builder, "'———— v%s\n", versions[len(versions)-1])
		}

		fmt.Println(builder.String())
	},
}
