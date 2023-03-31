package cmd

import (
	"github.com/spf13/cobra"
)

var mainCommand = &cobra.Command{
	Use: "docr command [options] arguments",
	Run: func(*cobra.Command, []string) {},
}

func init() {
	mainCommand.AddCommand(envCommand)
}

func Execute() {
	_ = mainCommand.Execute()
}
