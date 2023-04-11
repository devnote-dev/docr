package cmd

import "github.com/spf13/cobra"

var mainCommand = &cobra.Command{
	Use: "docr command [options] arguments",
}

func init() {
	mainCommand.AddCommand(envCommand)
	mainCommand.AddCommand(libraryCommand)
	mainCommand.AddCommand(searchCommand)
	mainCommand.AddCommand(lookupCommand)
}

func Execute() {
	_ = mainCommand.Execute()
}
