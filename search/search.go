package search

import (
	"github.com/devnote-dev/docr/crystal"
	"github.com/devnote-dev/docr/levenshtein"
)

type Result struct {
	Name   string
	Source *crystal.Location
}

func FindConstants(lib *crystal.Type, symbol string) []*Result {
	if len(lib.Constants) == 0 {
		return nil
	}

	consts := levenshtein.SortBy(symbol, lib.Constants, func(c *crystal.Constant) string {
		return c.Name
	})

	r := make([]*Result, len(consts))
	for i, c := range consts {
		r[i] = &Result{Name: c.Name, Source: nil}
	}

	return r
}

func FindConstructors(lib *crystal.Type, symbol string) []*Result {
	if len(lib.Constructors) == 0 {
		return nil
	}

	consts := levenshtein.SortBy(symbol, lib.Constructors, func(d *crystal.Definition) string {
		return d.Name
	})

	r := make([]*Result, len(consts))
	for i, c := range consts {
		r[i] = &Result{Name: c.Name, Source: nil}
	}

	return r
}

func FindMethods(lib *crystal.Type, symbol string) []*Result {
	if len(lib.ClassMethods) == 0 {
		return nil
	}

	defs := levenshtein.SortBy(symbol, lib.ClassMethods, func(d *crystal.Definition) string {
		return d.Name
	})

	r := make([]*Result, len(defs))
	for i, d := range defs {
		r[i] = &Result{Name: d.Name, Source: d.Location}
	}

	return r
}

func FindMacros(lib *crystal.Type, symbol string) []*Result {
	if len(lib.Macros) == 0 {
		return nil
	}

	defs := levenshtein.SortBy(symbol, lib.Macros, func(d *crystal.Definition) string {
		return d.Name
	})

	r := make([]*Result, len(defs))
	for i, m := range defs {
		r[i] = &Result{Name: m.Name, Source: m.Location}
	}

	return r
}

func FindTypes(lib *crystal.Type, symbol string) []*Result {
	if len(lib.Types) == 0 {
		return nil
	}

	types := levenshtein.SortBy(symbol, lib.Types, func(t *crystal.Type) string {
		return t.FullName
	})

	r := make([]*Result, len(types))
	for i, t := range types {
		r[i] = &Result{Name: t.FullName, Source: t.Locations[0]}
	}

	return r
}
