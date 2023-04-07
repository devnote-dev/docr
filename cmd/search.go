package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/devnote-dev/docr/crystal"
	"github.com/devnote-dev/docr/env"
	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

var (
	red     = color.New(color.FgRed).FprintFunc()
	blue    = color.New(color.FgBlue).FprintFunc()
	magenta = color.New(color.FgMagenta).FprintFunc()
	white   = color.New(color.FgWhite).FprintFunc()
	reset   = color.New(color.Reset).FprintFunc()
)

var searchCommand = &cobra.Command{
	Use: "search symbol",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			var input string

			fmt.Print("Enter query: ")
			fmt.Scanln(&input)
			args = strings.Split(input, " ")
		}

		q, err := crystal.ParseQuery(args)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}

		versions, err := env.GetLibraryVersions(q.Library)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}

		if len(versions) == 0 {
			fmt.Fprintf(os.Stderr, "latest %s documentation is not available\n", q.Library)
			return
		}

		latest := versions[len(versions)-1]
		lib, err := env.GetLibrary(q.Library, latest)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}

		types := crystal.FilterTypes(lib, q.Symbol)
		if len(types) == 0 {
			fmt.Fprintln(os.Stderr, "no documentation found for symbol")
			return
		}
		fmt.Print("Search Results:\n\n")

		builder := strings.Builder{}

		for k, v := range types {
			switch k {
			case crystal.KConstant:
				for _, c := range v {
					blue(&builder, c.Value[0])
					if len(c.Value) == 2 {
						reset(&builder, "::")
						blue(&builder, c.Value[1])
					}

					if c.Source != nil {
						white(&builder, " (", c.Source.File, "#L", c.Source.Line, ")")
					} else {
						white(&builder, " (top level)")
					}
					builder.WriteRune('\n')
				}
			case crystal.KConstructor:
				fallthrough
			case crystal.KCMethod:
				for _, m := range v {
					if m.Source != nil {
						white(&builder, m.Source.File, "#L", m.Source.Line, "\n")
					} else {
						white(&builder, "unknown source\n")
					}

					red(&builder, "def ")
					if m.Value[0] != "" {
						blue(&builder, m.Value[0])
						reset(&builder, ".")
					}
					magenta(&builder, m.Value[1])
					reset(&builder, m.Value[2])
					builder.WriteString("\n\n")
				}
			case crystal.KIMethod:
				for _, m := range v {
					if m.Source != nil {
						white(&builder, m.Source.File, "#L", m.Source.Line, "\n")
					} else {
						white(&builder, "unknown source\n")
					}

					red(&builder, "def ")
					if m.Value[0] != "" {
						blue(&builder, m.Value[0])
						reset(&builder, "#")
					}
					magenta(&builder, m.Value[1])
					reset(&builder, m.Value[2])
					builder.WriteString("\n\n")
				}
			case crystal.KMacro:
				for _, m := range v {
					if m.Source != nil {
						white(&builder, m.Source.File, "#L", m.Source.Line, "\n")
					} else {
						white(&builder, "unknown source\n")
					}

					red(&builder, "macro ")
					if m.Value[0] != "" {
						blue(&builder, m.Value[0])
						reset(&builder, "#")
					}
					magenta(&builder, m.Value[1])
					reset(&builder, m.Value[2])
					builder.WriteString("\n\n")
				}
			}
		}

		fmt.Print(strings.TrimSuffix(builder.String(), "\n"))
	},
}
