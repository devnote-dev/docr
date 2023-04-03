package search

import (
	"errors"
	"regexp"
	"strings"
)

var libRule = regexp.MustCompile(`\A[a-z0-9_-]+\z`)

type Query struct {
	Library string
	Types   []string
	Symbol  string
}

// 1: library Symbol
// 2: library Type Symbol
// 1: library Type.Symbol
// 1: library Type::Symbol
// 2: library Type::Symbol Symbol
func ParseQuery(args []string) (*Query, error) {
	var err error
	var types []string
	var symbol string

	lib := "crystal"

	if len(args) > 1 && libRule.MatchString(args[0]) {
		lib = args[0]
		args = args[1:]
	}

	if len(args) == 2 {
		types = strings.Split(args[0], "::")
		symbol, err = extractSymbol(args[1])
	} else {
		types = strings.Split(args[0], "::")
		symbol = types[len(types)-1]
		if len(types) == 1 {
			types = []string{}
		} else {
			types = types[:1]
		}
	}

	if err != nil {
		return nil, err
	}

	return &Query{lib, types, symbol}, nil
}

func extractSymbol(str string) (string, error) {
	parts := strings.Split(str, ".")
	if len(parts) > 2 {
		return "", errors.New("invalid module or type path")
	}

	if len(parts) == 1 {
		return str, nil
	}

	return parts[1], nil
}
