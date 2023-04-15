package cmd

import (
	"github.com/devnote-dev/docr/env"
	"github.com/devnote-dev/docr/log"
	"github.com/spf13/cobra"
)

// TODO: should probably prompt with this and override with --yes
var removeCommand = &cobra.Command{
	Use:   "remove name [version]",
	Short: "removes a library",
	Long: "Removes an imported library. If the 'version' argument is not specified, all\n" +
		"versions of the library are removed.",
	Run: func(cmd *cobra.Command, args []string) {
		log.Configure(cmd)
		if err := rangeArgs(1, 2, args); err != nil {
			log.Error("%v\n", err)
			cmd.Help()
			return
		}

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
