package cmd

import (
	"fmt"
	"os"

	"github.com/devnote-dev/docr/crystal"
	"github.com/devnote-dev/docr/env"
	"github.com/devnote-dev/docr/levenshtein"
	"github.com/spf13/cobra"
)

var searchCommand = &cobra.Command{
	Use: "search symbol",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			fmt.Fprintln(os.Stderr, "no arguments provided")
			return
		}

		module := ""
		symbol := args[0]
		if len(args) > 1 {
			module = symbol
			// symbol = args[1]
		}

		if module == "" {
			versions, err := env.GetLibraryVersions("crystal")
			if err != nil {
				fmt.Fprintln(os.Stderr, err)
				return
			}

			if len(versions) == 0 {
				fmt.Fprintln(os.Stderr, "latest crystal standard library documentation is not available")
				return
			}

			latest := versions[len(versions)-1]
			lib, err := env.GetLibrary("crystal", latest)
			if err != nil {
				fmt.Fprintln(os.Stderr, err)
				return
			}

			c := findConstant(lib, symbol)
			if c != nil {
				fmt.Printf("%v\n", c)
				return
			}

			x := findConstructor(lib, symbol)
			if x != nil {
				fmt.Printf("%v\n", x)
				return
			}

			m := findMethod(lib, symbol)
			if m != nil {
				fmt.Printf("%v\n", m)
				return
			}

			m = findMacro(lib, symbol)
			if m != nil {
				fmt.Printf("%v\n", m)
				return
			}

			d := findType(lib, symbol)
			if d != nil {
				fmt.Printf("%v\n", d)
				return
			}

			fmt.Fprintln(os.Stderr, "no documentation found for symbol")
		}
	},
}

func findConstant(lib *crystal.Type, symbol string) *crystal.Constant {
	r := levenshtein.Find(symbol, lib.ConstantNames()...)
	if r != "" {
		for _, c := range lib.Constants {
			if r == c.Name {
				return c
			}
		}
	}

	return nil
}

func findConstructor(lib *crystal.Type, symbol string) *crystal.Definition {
	r := levenshtein.Find(symbol, lib.ConstructorNames()...)
	if r != "" {
		for _, c := range lib.Constructors {
			if r == c.Name {
				return c
			}
		}
	}

	return nil
}

func findMethod(lib *crystal.Type, symbol string) *crystal.Definition {
	r := levenshtein.Find(symbol, lib.ClassMethodNames()...)
	if r != "" {
		for _, m := range lib.ClassMethods {
			if r == m.Name {
				return m
			}
		}
	}

	return nil
}

func findMacro(lib *crystal.Type, symbol string) *crystal.Definition {
	r := levenshtein.Find(symbol, lib.MacroNames()...)
	if r != "" {
		for _, m := range lib.Macros {
			if r == m.Name {
				return m
			}
		}
	}

	return nil
}

func findType(lib *crystal.Type, symbol string) *crystal.Type {
	r := levenshtein.Find(symbol, lib.MacroNames()...)
	if r != "" {
		for _, t := range lib.Types {
			if r == t.Name || r == t.FullName {
				return t
			}
		}
	}

	return nil
}
