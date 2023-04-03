package cmd

import (
	"fmt"
	"os"

	"github.com/devnote-dev/docr/crystal"
	"github.com/devnote-dev/docr/env"
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

		t := crystal.FindType(lib, q.Symbol)
		if t == nil {
			fmt.Fprintf(os.Stderr, "documentation for %s not found\n", q.Symbol)
			return
		}

		if v, ok := t.(*crystal.Constant); ok {
			fmt.Printf("%s = %s\n%s\n", v.Name, v.Value, v.Summary)
			return
		}

		if v, ok := t.(*crystal.Definition); ok {
			if v.Alias {
				fmt.Printf("alias %s = %s\n", v.Name, v.Aliased)
			} else if v.Enum {
				fmt.Printf("enum %s\n", v.Name)
				for _, c := range t.(*crystal.Type).Constants {
					fmt.Printf("  %s\n", c.Name)
				}
				fmt.Println("end")
			} else {
				fmt.Printf("%v\n", v)
			}
		}
	},
}
