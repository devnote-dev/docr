package crystal

import "github.com/devnote-dev/docr/levenshtein"

type Result struct {
	Value  []string
	Source *Location
}

func FilterConstants(lib *Type, symbol string) []*Result {
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

func FilterConstructors(lib *Type, symbol string) []*Result {
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

func FilterClassMethods(lib *Type, symbol string) []*Result {
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

func FilterInstanceMethods(lib *Type, symbol string) []*Result {
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

func FilterMacros(lib *Type, symbol string) []*Result {
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

func FilterTypes(lib *Type, symbol string) map[string][]*Result {
	res := map[string][]*Result{}

	if r := FilterConstants(lib, symbol); r != nil {
		res["Constants"] = r
	}

	if r := FilterConstructors(lib, symbol); r != nil {
		res["Constructors"] = r
	}

	if r := FilterClassMethods(lib, symbol); r != nil {
		res["Class Methods"] = r
	}

	if r := FilterInstanceMethods(lib, symbol); r != nil {
		res["Instance Methods"] = r
	}

	if r := FilterMacros(lib, symbol); r != nil {
		res["Macros"] = r
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
