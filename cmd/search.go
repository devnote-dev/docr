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

		q, err := search.ParseQuery(args)
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

		consts := search.FindConstants(lib, q.Symbol)
		constructors := search.FindConstructors(lib, q.Symbol)
		methods := search.FindMethods(lib, q.Symbol)
		macros := search.FindMacros(lib, q.Symbol)
		types := search.FindTypes(lib, q.Symbol)

		if consts == nil && constructors == nil && methods == nil && macros == nil && types == nil {
			fmt.Fprintln(os.Stderr, "no documentation found for symbol")
			return
		}

		builder := strings.Builder{}

		if len(consts) != 0 {
			builder.WriteString("Constants:\n")
			for _, c := range consts {
				s := "unknown"
				if c.Source != nil {
					s = c.Source.File
				}
				fmt.Fprintf(&builder, "%s (%s)", c.Name, s)
			}
			builder.WriteRune('\n')
		}

		if len(constructors) != 0 {
			builder.WriteString("Constructors:\n")
			for _, c := range constructors {
				s := "unknown"
				if c.Source != nil {
					s = c.Source.File
				}
				fmt.Fprintf(&builder, "%s (%s)", c.Name, s)
			}
			builder.WriteRune('\n')
		}

		if len(methods) != 0 {
			builder.WriteString("Methods:\n")
			for _, m := range methods {
				s := "unknown"
				if m.Source != nil {
					s = m.Source.File
				}
				fmt.Fprintf(&builder, "%s (%s)", m.Name, s)
			}
			builder.WriteRune('\n')
		}

		if len(macros) != 0 {
			builder.WriteString("Macros:\n")
			for _, m := range macros {
				s := "unknown"
				if m.Source != nil {
					s = m.Source.File
				}
				fmt.Fprintf(&builder, "%s (%s)", m.Name, s)
			}
			builder.WriteRune('\n')
		}

		if len(types) != 0 {
			builder.WriteString("Other Types:\n")
			for _, t := range types {
				s := "unknown"
				if t.Source != nil {
					s = t.Source.File
				}
				fmt.Fprintf(&builder, "%s (%s)", t.Name, s)
			}
			builder.WriteRune('\n')
		}

		fmt.Println(builder.String())
	},
}
