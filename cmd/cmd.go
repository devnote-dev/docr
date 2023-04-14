package cmd

import "github.com/spf13/cobra"

var mainCommand = &cobra.Command{
	Use: "docr command [options] arguments",
}

func init() {
	mainCommand.PersistentFlags().Bool("no-color", false, "disable ansi color")
	mainCommand.PersistentFlags().Bool("debug", false, "output debug information")
	mainCommand.CompletionOptions.DisableDefaultCmd = true

	mainCommand.AddCommand(envCommand)
	mainCommand.AddCommand(listCommand)
	mainCommand.AddCommand(aboutCommand)
	mainCommand.AddCommand(addCommand)
	// mainCommand.AddCommand(checkCommand)
	mainCommand.AddCommand(updateCommand)
	mainCommand.AddCommand(removeCommand)
	mainCommand.AddCommand(searchCommand)
	mainCommand.AddCommand(infoCommand)
}

func Execute() {
	_ = mainCommand.Execute()
}
