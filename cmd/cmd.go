package cmd

import "github.com/spf13/cobra"

var mainCommand = &cobra.Command{
	Use: "docr command [options] arguments",
}

func init() {
	mainCommand.PersistentFlags().Bool("no-color", false, "disable ansi color")
	mainCommand.PersistentFlags().Bool("debug", false, "output debug information")

	mainCommand.AddCommand(envCommand)
	mainCommand.AddCommand(libraryCommand)
	mainCommand.AddCommand(searchCommand)
	mainCommand.AddCommand(lookupCommand)
}

func Execute() {
	_ = mainCommand.Execute()
}
