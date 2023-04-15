package cmd

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/glamour"
	"github.com/devnote-dev/docr/crystal"
	"github.com/devnote-dev/docr/env"
	"github.com/devnote-dev/docr/log"
	"github.com/microcosm-cc/bluemonday"
	"github.com/spf13/cobra"
)

var infoCommand = &cobra.Command{
	Use:   "info symbol [symbol]",
	Short: "gets information about a symbol",
	Long: `Gets information about a specified type/namespace or symbol. This supports
Crystal path syntax, meaning the following commands are valid:

• docr info JSON::Any.as_s
• docr info JSON::Any#as_s
• docr info JSON::Any as_s

However, the following commands are not valid:

• docr info JSON Any as_s
• docr info JSON Any.as_s
• docr info JSON Any#as_s

This is because the first argument is parsed as the base type or namespace to
look in, and the second argument is parsed as the symbol to look for. In the
first example, JSON::Any is the namespace and as_s the symbol, whereas in the
second example, JSON is the namespace and Any as_s is the symbol, which is
invalid. This doesn't mean you have to specify the namespace of a symbol, Docr
can determine whether an argument is a type/namespace or symbol and handle
it accordingly.`,
	Run: func(cmd *cobra.Command, args []string) {
		log.Configure(cmd)
		if err := rangeArgs(1, 3, args); err != nil {
			log.Error(err)
			cmd.HelpFunc()(cmd, args)
			return
		}

		q, err := crystal.ParseQuery(args)
		if err != nil {
			log.Error("failed to parse query:")
			log.Error(err)
			return
		}

		versions, err := env.GetLibraryVersions(q.Library)
		if err != nil {
			log.Error("failed to get library versions:")
			log.Error(err)
			return
		}

		if len(versions) == 0 {
			log.Errorf("documentation for %s is not available", q.Library)
			log.Errorf("did you mean to run 'docr add %s'?", q.Library)
			return
		}

		ver, _ := cmd.Flags().GetString("version")
		if ver == "" {
			ver = versions[len(versions)-1]
		}

		lib, err := env.GetLibrary(q.Library, ver)
		if err != nil {
			log.Errorf("documentation for library %s version %s is not available", q.Library, ver)
			return
		}

		if len(q.Types) != 0 {
			res := crystal.ResolveType(lib, q.Types)
			if res == nil && q.Library != "crystal" {
				res = crystal.ResolveType(lib.Types[0], q.Types)
			}

			if res == nil {
				log.Error("could not resolve types or namespaces for that symbol")
				return
			}

			lib = res
		}

		v := crystal.FindType(lib, q.Symbol)
		if v == nil {
			log.Errorf("no documentation found for symbol '%s'", q.Symbol)
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
				white(&builder, "  (cannot resolve locations)\n")
			} else {
				for _, loc := range lib.Locations {
					fmt.Fprintf(&builder, "• %s:%d\n", loc.File, loc.Line)
				}
			}

			if c.Doc == "" {
				white(&builder, "\n  (no information available)")
			} else {
				if out, err := term.Render(c.Doc); err == nil {
					builder.WriteString(out)
				} else {
					white(&builder, "\n  (error rendering documentation)")
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

			if lib.Name != "Top Level Namespace" && lib.Name != "Macros" {
				blue(&builder, lib.Name)
				reset(&builder, ".") // TODO: distinguish instance methods
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
				white(&builder, "\n  (no information available)")
			} else {
				if out, err := term.Render(d.Doc); err == nil {
					builder.WriteString(out)
				} else {
					white(&builder, "\n  (error rendering documentation)")
				}
			}
		}

		if t, ok := v.(*crystal.Type); ok {
			if t.Abstract {
				red(&builder, "abstract ")
			}
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
				if t.SuperClass != nil && t.SuperClass.FullName != "Reference" && t.SuperClass.FullName != "Value" {
					reset(&builder, " < ")
					blue(&builder, t.SuperClass.FullName)
				}
				builder.WriteRune('\n')
			}

			if len(t.Included) != 0 || len(t.Constants) != 0 {
				if len(t.Included) != 0 {
					for _, i := range t.Included {
						red(&builder, "  include ")
						blue(&builder, i.FullName, "\n")
					}
					if len(t.Constants) != 0 {
						builder.WriteRune('\n')
					}
				}

				if len(t.Constants) != 0 {
					for _, c := range t.Constants {
						blue(&builder, "  ", c.Name)
						reset(&builder, " = ", c.Value, "\n")
					}
				}

				red(&builder, "end\n")
			}

			if t.Summary != "" {
				if out, err := term.Render(policy.Sanitize(t.Summary)); err == nil {
					builder.WriteString(strings.TrimSuffix(out, "\n"))
				}
			}

			builder.WriteString("\nDefined:\n")
			if len(t.Locations) == 0 {
				white(&builder, "  (cannot resolve locations)\n")
			} else {
				for _, loc := range t.Locations {
					fmt.Fprintf(&builder, "• %s:%d\n", loc.File, loc.Line)
				}
			}

			if len(t.Constructors) != 0 {
				builder.WriteString("\nConstructors:\n")
				for _, c := range t.Constructors {
					red(&builder, "  def ")
					magenta(&builder, c.Name)
					reset(&builder, c.Args, "\n")
				}
			}

			if s := len(t.ClassMethods); s != 0 {
				fmt.Fprintf(&builder, "\nClass methods: %d\n", s)
			}
			if s := len(t.InstanceMethods); s != 0 {
				fmt.Fprintf(&builder, "\nInstance methods: %d\n", s)
			}

			if t.Doc == "" {
				white(&builder, "\n  (no information available)")
			} else {
				if out, err := term.Render(t.Doc); err == nil {
					builder.WriteString(out)
				} else {
					white(&builder, "\n  (error rendering documentation)")
				}
			}
		}

		fmt.Print(strings.TrimSuffix(builder.String(), "\n"))
	},
}

func init() {
	infoCommand.Flags().String("version", "", "the version to install")
}
