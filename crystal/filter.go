package crystal

import "github.com/devnote-dev/docr/levenshtein"

type Result struct {
	Name   string
	Source *Location
}

func FilterConstants(lib *Type, symbol string) []*Result {
	if len(lib.Constants) == 0 {
		return nil
	}

	consts := levenshtein.SortBy(symbol, lib.Constants, func(c *Constant) string {
		return c.Name
	})

	r := make([]*Result, len(consts))
	for i, c := range consts {
		r[i] = &Result{Name: c.Name, Source: nil}
	}

	return r
}

func FilterConstructors(lib *Type, symbol string) []*Result {
	if len(lib.Constructors) == 0 {
		return nil
	}

	consts := levenshtein.SortBy(symbol, lib.Constructors, func(d *Definition) string {
		return d.Name
	})

	r := make([]*Result, len(consts))
	for i, c := range consts {
		r[i] = &Result{Name: c.Name, Source: nil}
	}

	return r
}

func FilterClassMethods(lib *Type, symbol string) []*Result {
	if len(lib.ClassMethods) == 0 {
		return nil
	}

	defs := levenshtein.SortBy(symbol, lib.ClassMethods, func(d *Definition) string {
		return d.Name
	})

	r := make([]*Result, len(defs))
	for i, d := range defs {
		r[i] = &Result{Name: d.Name, Source: d.Location}
	}

	return r
}

func FilterInstanceMethods(lib *Type, symbol string) []*Result {
	if len(lib.InstanceMethods) == 0 {
		return nil
	}

	defs := levenshtein.SortBy(symbol, lib.InstanceMethods, func(d *Definition) string {
		return d.Name
	})

	r := make([]*Result, len(defs))
	for i, d := range defs {
		r[i] = &Result{Name: d.Name, Source: d.Location}
	}

	return r
}

func FilterMacros(lib *Type, symbol string) []*Result {
	if len(lib.Macros) == 0 {
		return nil
	}

	defs := levenshtein.SortBy(symbol, lib.Macros, func(d *Definition) string {
		return d.Name
	})

	r := make([]*Result, len(defs))
	for i, m := range defs {
		r[i] = &Result{Name: m.Name, Source: m.Location}
	}

	return r
}

func FilterTypes(lib *Type, symbol string) []*Result {
	var res []*Result

	if r := FilterConstants(lib, symbol); r != nil {
		res = append(res, r...)
	}

	if r := FilterConstructors(lib, symbol); r != nil {
		res = append(res, r...)
	}

	if r := FilterClassMethods(lib, symbol); r != nil {
		res = append(res, r...)
	}

	if r := FilterInstanceMethods(lib, symbol); r != nil {
		res = append(res, r...)
	}

	if r := FilterMacros(lib, symbol); r != nil {
		res = append(res, r...)
	}

	if len(lib.Types) != 0 {
		for _, t := range lib.Types {
			res = append(res, FilterTypes(t, symbol)...)
		}
	}

	return res
}
