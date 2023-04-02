package search

import (
	"sort"

	"github.com/devnote-dev/docr/crystal"
)

type Result struct {
	Name   string
	Source *crystal.Location
}

type constants []*crystal.Constant

func (c constants) Len() int           { return len(c) }
func (c constants) Swap(i, j int)      { c[i], c[j] = c[j], c[i] }
func (c constants) Less(i, j int) bool { return c[i].Name < c[j].Name }

type definitions []*crystal.Definition

func (d definitions) Len() int           { return len(d) }
func (d definitions) Swap(i, j int)      { d[i], d[j] = d[j], d[i] }
func (d definitions) Less(i, j int) bool { return d[i].Name < d[j].Name }

type types []*crystal.Type

func (t types) Len() int           { return len(t) }
func (t types) Swap(i, j int)      { t[i], t[j] = t[j], t[i] }
func (t types) Less(i, j int) bool { return t[i].FullName < t[j].FullName }

func FindConstants(lib *crystal.Type, symbol string) []*Result {
	if lib.Constants == nil {
		return nil
	}

	if len(lib.Constants) == 0 {
		return nil
	}

	consts := (constants)(lib.Constants)
	sort.Sort(consts)

	r := make([]*Result, len(lib.Constants))
	for i, c := range consts {
		r[i] = &Result{Name: c.Name, Source: nil}
	}

	return r
}

func FindConstructors(lib *crystal.Type, symbol string) []*Result {
	if lib.Constructors == nil {
		return nil
	}

	if len(lib.Constructors) == 0 {
		return nil
	}

	defs := (definitions)(lib.Constructors)
	sort.Sort(defs)

	r := make([]*Result, len(lib.Constructors))
	for i, c := range defs {
		r[i] = &Result{Name: c.Name, Source: nil}
	}

	return r
}

func FindMethods(lib *crystal.Type, symbol string) []*Result {
	if lib.ClassMethods == nil {
		return nil
	}

	if len(lib.ClassMethods) == 0 {
		return nil
	}

	defs := (definitions)(lib.ClassMethods)
	sort.Sort(defs)

	r := make([]*Result, len(lib.ClassMethods))
	for i, d := range defs {
		r[i] = &Result{Name: d.Name, Source: d.Location}
	}

	return r
}

func FindMacros(lib *crystal.Type, symbol string) []*Result {
	if lib.Macros == nil {
		return nil
	}

	if len(lib.Macros) == 0 {
		return nil
	}

	defs := (definitions)(lib.Macros)
	sort.Sort(defs)

	r := make([]*Result, len(lib.Macros))
	for i, m := range defs {
		r[i] = &Result{Name: m.Name, Source: m.Location}
	}

	return r
}

func FindTypes(lib *crystal.Type, symbol string) []*Result {
	if lib.Types == nil {
		return nil
	}

	if len(lib.Types) == 0 {
		return nil
	}

	defs := (types)(lib.Types)
	sort.Sort(defs)

	r := make([]*Result, len(lib.Types))
	for i, t := range defs {
		r[i] = &Result{Name: t.FullName, Source: t.Locations[0]}
	}

	return r
}
