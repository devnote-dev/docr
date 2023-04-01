package search

import "strings"

type SearchInfo struct {
	module string
	symbol string
	field  string
}

func ParseInfo(args []string) SearchInfo {
	var module, symbol, field string

	if strings.Contains(args[0], "::") {
		parts := strings.Split(args[0], "::")
		symbol = parts[len(parts)-1]
		module = strings.Join(parts, "::")
	} else if strings.Contains(args[0], ".") {
		parts := strings.Split(args[0], ".")
		field = parts[len(parts)-1]
	}

	if len(args) > 1 {
		if strings.Contains(args[1], ".") {
			parts := strings.Split(args[1], ".")
			field = parts[len(parts)-1]
		}
	}

	return SearchInfo{module, symbol, field}
}
