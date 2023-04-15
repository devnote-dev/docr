package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var mainCommand = &cobra.Command{
	Use: "docr command [options] arguments",
	Long: "A CLI tool for searching Crystal documentation, with version support\n" +
		"for the standard library documentation and documentation for third-party\n" +
		"libraries (or shards).",
}

var versionCommand = &cobra.Command{
	Use:   "version",
	Short: "shows version information",
	Long:  "Shows the version information for Docr.",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("Docr %s (%s)\n", Version, Build)
	},
}

func init() {
	mainCommand.PersistentFlags().Bool("no-color", false, "disable ansi color")
	mainCommand.PersistentFlags().Bool("debug", false, "output debug information")
	mainCommand.CompletionOptions.DisableDefaultCmd = true
	mainCommand.SetHelpTemplate(ansiEncode.Replace(`$BUsage$R
• {{.UseLine}}
{{if gt (len .Commands) 0}}
$BCommands$R{{range .Commands}}
• $S{{rpad .Name .NamePadding}}$R {{.Short}}{{end}}
{{end}}
$BOptions$R{{range .LocalFlags.FlagUsages | splitLines}}
{{.}}{{end}}

$BDescription$R
{{.Long}}
{{if gt (len .Commands) 0}}
Use '$Bdocr{{if (eq .Name "docr" | not)}} {{.Name}}{{end}} --help$R' for more information about a command{{end}}
`)) // doesn't respect colour rules...

	cobra.AddTemplateFunc("splitLines", splitLines)

	mainCommand.AddCommand(versionCommand)
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
