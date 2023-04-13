package cmd

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/charmbracelet/glamour"
	"github.com/devnote-dev/docr/env"
	"github.com/devnote-dev/docr/log"
	"github.com/spf13/cobra"
)

var aboutCommand = &cobra.Command{
	Use: "about name [version]",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			return
		}
		log.Configure(cmd)

		name := args[0]
		var version string
		if len(args) > 1 {
			version = args[1]
		} else {
			ver, err := env.GetLibraryVersions(name)
			if err != nil {
				log.Error("failed to get library versions:")
				log.Error(err)
				return
			}

			version = ver[len(ver)-1]
		}

		buf, err := os.ReadFile(filepath.Join(env.LibraryDir(), name, version, "README.md"))
		if err != nil {
			if os.IsNotExist(err) {
				log.Errorf("library %s version %s has no README", name, version)
			} else {
				log.Error(err)
			}
			return
		}

		term, _ := glamour.NewTermRenderer(
			glamour.WithAutoStyle(),
		)

		out, err := term.Render(string(buf))
		if err != nil {
			log.Errorf("failed to render library %s README:", name)
			log.Error(err)
			return
		}

		fmt.Print(out)
	},
}
