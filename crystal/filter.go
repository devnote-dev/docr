package crystal

import "github.com/devnote-dev/docr/levenshtein"

type Result struct {
	Value  []string
	Source *Location
}

type CrType int

const (
	KConstant CrType = iota
	KConstructor
	KCMethod
	KIMethod
	KMacro
)

func FilterTypes(lib *Type, symbol string) map[CrType][]*Result {
	res := map[CrType][]*Result{}

	if r := filterConstants(lib, symbol); r != nil {
		res[KConstant] = r
	}

	if r := filterConstructors(lib, symbol); r != nil {
		res[KConstructor] = r
	}

	if r := filterClassMethods(lib, symbol); r != nil {
		res[KCMethod] = r
	}

	if r := filterInstanceMethods(lib, symbol); r != nil {
		res[KIMethod] = r
	}

	if r := filterMacros(lib, symbol); r != nil {
		res[KMacro] = r
	}

	if len(lib.Types) != 0 {
		for _, t := range lib.Types {
			for k, v := range FilterTypes(t, symbol) {
				if r, ok := res[k]; ok {
					r = append(r, v...)
					res[k] = r
				} else {
					res[k] = r
				}
			}
		}
	}

	return res
}

func filterConstants(lib *Type, symbol string) []*Result {
	if len(lib.Constants) == 0 {
		return nil
	}

	consts := levenshtein.SortBy(symbol, lib.Constants, func(c *Constant) string {
		return c.Name
	})
	if len(consts) == 0 {
		return nil
	}

	r := make([]*Result, len(consts))
	for i, c := range consts {
		r[i] = &Result{Value: []string{c.Name}}
	}

	return r
}

func filterConstructors(lib *Type, symbol string) []*Result {
	if len(lib.Constructors) == 0 {
		return nil
	}

	consts := levenshtein.SortBy(symbol, lib.Constructors, func(d *Definition) string {
		return d.Name
	})
	if len(consts) == 0 {
		return nil
	}

	r := make([]*Result, len(consts))
	for i, c := range consts {
		r[i] = &Result{Value: []string{lib.Name, c.Name, c.Args}}
	}

	return r
}

func filterClassMethods(lib *Type, symbol string) []*Result {
	if len(lib.ClassMethods) == 0 {
		return nil
	}

	defs := levenshtein.SortBy(symbol, lib.ClassMethods, func(d *Definition) string {
		return d.Name
	})
	if len(defs) == 0 {
		return nil
	}

	r := make([]*Result, len(defs))
	for i, d := range defs {
		r[i] = &Result{Value: []string{lib.Name, d.Name, d.Args}, Source: d.Location}
	}

	return r
}

func filterInstanceMethods(lib *Type, symbol string) []*Result {
	if len(lib.InstanceMethods) == 0 {
		return nil
	}

	defs := levenshtein.SortBy(symbol, lib.InstanceMethods, func(d *Definition) string {
		return d.Name
	})
	if len(defs) == 0 {
		return nil
	}

	r := make([]*Result, len(defs))
	for i, d := range defs {
		r[i] = &Result{Value: []string{lib.Name, d.Name, d.Args}, Source: d.Location}
	}

	return r
}

func filterMacros(lib *Type, symbol string) []*Result {
	if len(lib.Macros) == 0 {
		return nil
	}

	defs := levenshtein.SortBy(symbol, lib.Macros, func(d *Definition) string {
		return d.Name
	})
	if len(defs) == 0 {
		return nil
	}

	r := make([]*Result, len(defs))
	for i, m := range defs {
		r[i] = &Result{Value: []string{lib.Name, m.Name, m.Args}, Source: m.Location}
	}

	return r
}
