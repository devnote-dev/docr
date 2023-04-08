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
	Use:     "lookup symbol [symbol]",
	Aliases: []string{"info", "i"},
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
		policy := bluemonday.StrictPolicy().AllowElements("a", "code")
		term, _ := glamour.NewTermRenderer(
			glamour.WithAutoStyle(),
		)

		if c, ok := v.(*crystal.Constant); ok {
			if lib.Name != "Top Level Namespace" && lib.Name != "Macros" {
				blue(&builder, lib.Name)
			}
			reset(&builder, "::")
			blue(&builder, c.Name)
			reset(&builder, " = ", c.Value, "\n")

			if c.Summary != "" {
				if out, err := term.Render(policy.Sanitize(c.Summary)); err == nil {
					builder.WriteString(strings.TrimSuffix(out, "\n"))
				}
			}

			builder.WriteString("\nDefined:\n")
			if len(lib.Locations) == 0 {
				white(&builder, "(cannot resolve locations)\n")
			} else {
				for _, loc := range lib.Locations {
					fmt.Fprintf(&builder, "• %s:%d\n", loc.File, loc.Line)
				}
			}

			if c.Doc == "" {
				white(&builder, "\n(no information available)")
			} else {
				if out, err := term.Render(c.Doc); err == nil {
					builder.WriteString(out)
				} else {
					white(&builder, "\n(error rendering documentation)")
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

			if strings.Contains(d.HTMLID, "macro") {
				red(&builder, "macro ")
			} else {
				red(&builder, "def ")
			}
			magenta(&builder, d.Name)
			reset(&builder, d.Args, "\n")

			if d.Summary != "" {
				if out, err := term.Render(policy.Sanitize(d.Summary)); err == nil {
					builder.WriteString(strings.TrimSuffix(out, "\n"))
				}
			}
			fmt.Fprintf(&builder, "\nDefined:\n• %s:%d\n", d.Location.File, d.Location.Line)

			if d.Doc == "" {
				white(&builder, "\n(no information available)")
			} else {
				if out, err := term.Render(d.Doc); err == nil {
					builder.WriteString(out)
				} else {
					white(&builder, "\n(error rendering documentation)")
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
				if out, err := term.Render(policy.Sanitize(t.Summary)); err == nil {
					builder.WriteString(strings.TrimSuffix(out, "\n"))
				}
			}

			builder.WriteString("\nDefined:\n")
			if len(lib.Locations) == 0 {
				white(&builder, "(cannot resolve locations)\n")
			} else {
				for _, loc := range lib.Locations {
					fmt.Fprintf(&builder, "• %s:%d\n", loc.File, loc.Line)
				}
			}

			if t.Doc == "" {
				white(&builder, "\n(no information available)")
			} else {
				if out, err := term.Render(t.Doc); err == nil {
					builder.WriteString(out)
				} else {
					white(&builder, "\n(error rendering documentation)")
				}
			}
		}

		fmt.Print(strings.TrimSuffix(builder.String(), "\n"))
	},
}
