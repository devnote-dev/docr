package cmd

import (
	"fmt"

	"github.com/devnote-dev/docr/search"
	"github.com/spf13/cobra"
)

var searchCommand = &cobra.Command{
	Use: "search symbol",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("%v\n", search.ParseInfo(args))
	},
}
