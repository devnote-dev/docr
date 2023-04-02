package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/devnote-dev/docr/env"
	"github.com/devnote-dev/docr/search"
	"github.com/spf13/cobra"
)

var searchCommand = &cobra.Command{
	Use: "search symbol",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			fmt.Fprintln(os.Stderr, "no arguments provided")
			return
		}

		module := "crystal"
		symbol := args[0]
		if len(args) > 1 {
			module = symbol
			symbol = args[1]
		}

		versions, err := env.GetLibraryVersions(module)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}

		if len(versions) == 0 {
			fmt.Fprintf(os.Stderr, "latest %s documentation is not available\n", module)
			return
		}

		latest := versions[len(versions)-1]
		lib, err := env.GetLibrary(module, latest)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}

		consts := search.FindConstants(lib, symbol)
		constructors := search.FindConstructors(lib, symbol)
		methods := search.FindMethods(lib, symbol)
		macros := search.FindMacros(lib, symbol)
		types := search.FindTypes(lib, symbol)

		if consts == nil && constructors == nil && methods == nil && macros == nil && types == nil {
			fmt.Fprintln(os.Stderr, "no documentation found for symbol")
			return
		}

		builder := strings.Builder{}

		if len(consts) != 0 {
			builder.WriteString("Constants:")
			for _, c := range consts {
				s := "unknown"
				if c.Source != nil {
					s = c.Source.File
				}
				fmt.Fprintf(&builder, "\n  %s (%s)", c.Name, s)
			}
			builder.WriteRune('\n')
		}

		if len(constructors) != 0 {
			builder.WriteString("Constructors:")
			for _, c := range constructors {
				s := "unknown"
				if c.Source != nil {
					s = c.Source.File
				}
				fmt.Fprintf(&builder, "\n  %s (%s)", c.Name, s)
			}
			builder.WriteRune('\n')
		}

		if len(methods) != 0 {
			builder.WriteString("Methods:")
			for _, m := range methods {
				s := "unknown"
				if m.Source != nil {
					s = m.Source.File
				}
				fmt.Fprintf(&builder, "\n  %s (%s)", m.Name, s)
			}
			builder.WriteRune('\n')
		}

		if len(macros) != 0 {
			builder.WriteString("Macros:")
			for _, m := range macros {
				s := "unknown"
				if m.Source != nil {
					s = m.Source.File
				}
				fmt.Fprintf(&builder, "\n  %s (%s)", m.Name, s)
			}
			builder.WriteRune('\n')
		}

		if len(types) != 0 {
			builder.WriteString("Other Types:")
			for _, t := range types {
				s := "unknown"
				if t.Source != nil {
					s = t.Source.File
				}
				fmt.Fprintf(&builder, "\n  %s (%s)", t.Name, s)
			}
			builder.WriteRune('\n')
		}

		fmt.Print(builder.String())
	},
}
