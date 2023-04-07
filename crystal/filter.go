package crystal

import "github.com/devnote-dev/docr/levenshtein"

type Result struct {
	Value  []string
	Source *Location
}

type KType int

const (
	KConstant KType = iota
	KModule
	KClass
	KStruct
	KEnum
	KAlias
	KConstructor
	KCMethod
	KIMethod
	KMacro
)

func FilterTypes(lib *Type, symbol string) map[KType][]*Result {
	res := map[KType][]*Result{}

	if r := filterConstants(lib, symbol); len(r) != 0 {
		res[KConstant] = r
	}

	if r := filterConstructors(lib, symbol); len(r) != 0 {
		res[KConstructor] = r
	}

	if r := filterClassMethods(lib, symbol); len(r) != 0 {
		res[KCMethod] = r
	}

	if r := filterInstanceMethods(lib, symbol); len(r) != 0 {
		res[KIMethod] = r
	}

	if r := filterMacros(lib, symbol); len(r) != 0 {
		res[KMacro] = r
	}

	if len(lib.Types) != 0 {
		for _, t := range lib.Types {
			if t.Name == symbol || t.FullName == symbol {
				var kt KType
				switch t.Kind {
				case "module":
					kt = KModule
				case "class":
					kt = KClass
				case "struct":
					kt = KStruct
				case "enum":
					kt = KEnum
				case "alias":
					kt = KAlias
				}

				// res[kt] = []*Result{{Value: []string{fixName(lib.Name), t.Name}, Source: t.Locations[0]}}
				val := make([]*Result, len(t.Locations))
				for i, loc := range t.Locations {
					val[i] = &Result{Value: []string{fixName(lib.Name), t.Name}, Source: loc}
				}
				res[kt] = val
				continue
			}

			for k, v := range FilterTypes(t, symbol) {
				if r, ok := res[k]; ok {
					r = append(r, v...)
					res[k] = r
				} else {
					res[k] = v
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

	var loc *Location
	if lib.Name != "Top Level Namespace" && len(lib.Locations) != 0 {
		loc = lib.Locations[0]
	}

	r := make([]*Result, len(consts))
	for i, c := range consts {
		r[i] = &Result{Value: []string{fixName(lib.Name), c.Name}, Source: loc}
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
		r[i] = &Result{Value: []string{fixName(lib.Name), c.Name, c.Args}}
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
		r[i] = &Result{Value: []string{fixName(lib.Name), d.Name, d.Args}, Source: d.Location}
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
		r[i] = &Result{Value: []string{fixName(lib.Name), d.Name, d.Args}, Source: d.Location}
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
		r[i] = &Result{Value: []string{fixName(lib.Name), m.Name, m.Args}, Source: m.Location}
	}

	return r
}

func fixName(s string) string {
	if s == "Top Level Namespace" || s == "Macros" {
		return ""
	}

	return s
}

func ResolveType(lib *Type, names []string) *Type {
	for _, t := range lib.Types {
		if t.Name == names[0] || t.FullName == names[0] {
			if len(names)-1 != 0 {
				return ResolveType(t, names[1:])
			}

			return t
		}
	}

	return nil
}
