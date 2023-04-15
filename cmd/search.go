package cmd

import (
	"fmt"
	"strings"

	"github.com/devnote-dev/docr/crystal"
	"github.com/devnote-dev/docr/env"
	"github.com/devnote-dev/docr/log"
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
	Use:   "search [library] symbol [symbol]",
	Short: "searches for a symbol",
	Long: "Searches for types/namespaces and symbols in a given library. If no library is\n" +
		"specified, the latest version of the Crystal standard library documentation is\n" +
		"used instead.",
	Run: func(cmd *cobra.Command, args []string) {
		log.Configure(cmd)
		if err := rangeArgs(1, 3, args); err != nil {
			log.Error("%v\n", err)
			cmd.Help()
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
			log.Error("no documentation is available for this library")
			return
		}

		ver, _ := cmd.Flags().GetString("version")
		if ver == "" {
			ver = versions[len(versions)-1]
		}

		lib, err := env.GetLibrary(q.Library, ver)
		if err != nil {
			log.Error("documentation for library %s version %s is not available", q.Library, ver)
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

		types := crystal.FilterTypes(lib, q.Symbol)
		if len(types) == 0 {
			log.Error("no documentation found for symbol '%s'", q.Symbol)
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
						white(&builder, " (", c.Source.File, ":", c.Source.Line, ")")
					} else {
						white(&builder, " (top level)")
					}
					builder.WriteRune('\n')
				}
				builder.WriteRune('\n')
			case crystal.KModule:
				for _, c := range v {
					red(&builder, "module ")
					blue(&builder, c.Value[0])
					if len(c.Value) == 2 {
						reset(&builder, "::")
						blue(&builder, c.Value[1])
					}

					if c.Source != nil {
						white(&builder, " (", c.Source.File, ":", c.Source.Line, ")")
					} else {
						white(&builder, " (top level)")
					}
					builder.WriteRune('\n')
				}
				builder.WriteRune('\n')
			case crystal.KClass:
				for _, c := range v {
					red(&builder, "class ")
					blue(&builder, c.Value[0])
					if len(c.Value) == 2 {
						reset(&builder, "::")
						blue(&builder, c.Value[1])
					}

					if c.Source != nil {
						white(&builder, " (", c.Source.File, ":", c.Source.Line, ")")
					} else {
						white(&builder, " (top level)")
					}
					builder.WriteRune('\n')
				}
				builder.WriteRune('\n')
			case crystal.KStruct:
				for _, c := range v {
					red(&builder, "struct ")
					blue(&builder, c.Value[0])
					if len(c.Value) == 2 {
						reset(&builder, "::")
						blue(&builder, c.Value[1])
					}

					if c.Source != nil {
						white(&builder, " (", c.Source.File, ":", c.Source.Line, ")")
					} else {
						white(&builder, " (top level)")
					}
					builder.WriteRune('\n')
				}
				builder.WriteRune('\n')
			case crystal.KEnum:
				for _, c := range v {
					red(&builder, "enum ")
					blue(&builder, c.Value[0])
					if len(c.Value) == 2 {
						reset(&builder, "::")
						blue(&builder, c.Value[1])
					}

					if c.Source != nil {
						white(&builder, " (", c.Source.File, ":", c.Source.Line, ")")
					} else {
						white(&builder, " (top level)")
					}
					builder.WriteRune('\n')
				}
				builder.WriteRune('\n')
			case crystal.KAlias:
				for _, c := range v {
					red(&builder, "alias ")
					blue(&builder, c.Value[0])
					if len(c.Value) == 2 {
						reset(&builder, "::")
						blue(&builder, c.Value[1])
					}

					if c.Source != nil {
						white(&builder, " (", c.Source.File, ":", c.Source.Line, ")")
					} else {
						white(&builder, " (top level)")
					}
					builder.WriteRune('\n')
				}
				builder.WriteRune('\n')
			case crystal.KConstructor:
				fallthrough
			case crystal.KCMethod:
				for _, m := range v {
					if m.Source != nil {
						white(&builder, m.Source.File, ":", m.Source.Line, "\n")
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
						white(&builder, m.Source.File, ":", m.Source.Line, "\n")
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
						white(&builder, m.Source.File, ":", m.Source.Line, "\n")
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

func init() {
	searchCommand.Flags().String("version", "", "the version to install")
}
