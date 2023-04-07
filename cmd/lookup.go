package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/charmbracelet/glamour"
	"github.com/devnote-dev/docr/crystal"
	"github.com/devnote-dev/docr/env"
	"github.com/microcosm-cc/bluemonday"
	"github.com/spf13/cobra"
)

var lookupCommand = &cobra.Command{
	Use: "lookup symbol [symbol]",
	Run: func(cmd *cobra.Command, args []string) {
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

		if len(q.Types) != 0 {
			lib = crystal.ResolveType(lib, q.Types)
		}
		if lib == nil {
			fmt.Fprintln(os.Stderr, "symbol not found")
			return
		}

		v := crystal.FindType(lib, q.Symbol)
		if v == nil {
			fmt.Fprintf(os.Stderr, "documentation for %s not found\n", q.Symbol)
			return
		}

		builder := strings.Builder{}
		policy := bluemonday.StrictPolicy()

		if c, ok := v.(*crystal.Constant); ok {
			if lib.Name != "Top Level Namespace" && lib.Name != "Macros" {
				blue(&builder, lib.Name)
			}
			reset(&builder, "::")
			blue(&builder, c.Name)
			reset(&builder, " = ", c.Value, "\n")

			if c.Summary != "" {
				builder.WriteString(policy.Sanitize(c.Summary))
				builder.WriteRune('\n')
			}

			builder.WriteString("\nDefined:\n")
			for _, loc := range lib.Locations {
				fmt.Fprintf(&builder, "• %s:%d\n", loc.File, loc.Line)
			}

			if c.Doc == "" {
				white(&builder, "\n(no information available)")
			} else {
				out, err := glamour.Render(policy.Sanitize(c.Doc), "dark")
				if err != nil {
					white(&builder, "\n(error rendering documentation)")
				} else {
					builder.WriteString(out)
				}
			}
		}

		if d, ok := v.(*crystal.Definition); ok {
			if d.Def != nil {
				if d.Def.Visibility != "Public" {
					red(&builder, strings.ToLower(d.Def.Visibility), " ")
				}
			}

			if d.Abstract {
				red(&builder, "abstract ")
			}

			red(&builder, "def ")
			magenta(&builder, d.Name)
			reset(&builder, d.Args, "\n")

			if d.Summary != "" {
				builder.WriteString(policy.Sanitize(d.Summary))
				builder.WriteRune('\n')
			}
			fmt.Fprintf(&builder, "\nDefined:\n• %s:%d\n", d.Location.File, d.Location.Line)

			if d.Doc == "" {
				white(&builder, "\n(no information available)")
			} else {
				out, err := glamour.Render(policy.Sanitize(d.Doc), "dark")
				if err != nil {
					white(&builder, "\n(error rendering documentation)")
				} else {
					builder.WriteString(out)
				}
			}
		}

		if t, ok := v.(*crystal.Type); ok {
			red(&builder, t.Kind, " ")
			blue(&builder, t.FullName)

			if t.Alias {
				reset(&builder, " = ")
				blue(&builder, t.Aliased, "\n")
			} else if t.Enum {
				for _, c := range t.Constants {
					blue(&builder, "\n  ", c.Name)
					if c.Value != "" {
						reset(&builder, " = ", c.Value)
					}
				}
				red(&builder, "\nend\n")
			} else {
				builder.WriteRune('\n')
			}

			if t.Summary != "" {
				builder.WriteString(policy.Sanitize(t.Summary))
				builder.WriteRune('\n')
			}

			builder.WriteString("\nDefined:\n")
			for _, loc := range lib.Locations {
				fmt.Fprintf(&builder, "• %s:%d\n", loc.File, loc.Line)
			}

			if t.Doc == "" {
				white(&builder, "\n(no information available)")
			} else {
				out, err := glamour.Render(policy.Sanitize(t.Doc), "dark")
				if err != nil {
					white(&builder, "\n(error rendering documentation)")
				} else {
					builder.WriteString(out)
				}
			}
		}

		fmt.Print(strings.TrimSuffix(builder.String(), "\n"))
	},
}
