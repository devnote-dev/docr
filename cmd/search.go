package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/devnote-dev/docr/crystal"
	"github.com/devnote-dev/docr/env"
	"github.com/spf13/cobra"
)

var searchCommand = &cobra.Command{
	Use: "search symbol",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			fmt.Fprintln(os.Stderr, "no arguments provided")
			return
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

		consts := crystal.FilterConstants(lib, q.Symbol)
		constructors := crystal.FilterConstructors(lib, q.Symbol)
		class := crystal.FilterClassMethods(lib, q.Symbol)
		instance := crystal.FilterInstanceMethods(lib, q.Symbol)
		macros := crystal.FilterMacros(lib, q.Symbol)
		types := crystal.FilterTypes(lib, q.Symbol)

		if consts == nil && constructors == nil && class == nil && instance == nil && macros == nil && types == nil {
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

		if len(class) != 0 {
			builder.WriteString("Class Methods:\n")
			for _, m := range class {
				s := "unknown"
				if m.Source != nil {
					s = m.Source.File
				}
				fmt.Fprintf(&builder, "%s (%s)", m.Name, s)
			}
			builder.WriteRune('\n')
		}

		if len(instance) != 0 {
			builder.WriteString("Instace Methods:\n")
			for _, m := range instance {
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
		}

		fmt.Println(builder.String())
	},
}
