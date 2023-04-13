package cmd

import (
	"github.com/devnote-dev/docr/env"
	"github.com/devnote-dev/docr/log"
	"github.com/spf13/cobra"
)

var removeCommand = &cobra.Command{
	Use: "remove name [version]",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			return
		}
		log.Configure(cmd)

		var err error
		name := args[0]
		version := ""
		if len(args) > 1 {
			version = args[1]
		}

		if version == "" {
			err = env.RemoveLibrary(name)
		} else {
			err = env.RemoveLibraryVersion(name, version)
		}

		if err != nil {
			log.Error("failed to remove library:")
			log.Error(err)
		}
	},
}
