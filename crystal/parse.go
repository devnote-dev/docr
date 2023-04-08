package crystal

import (
	"errors"
	"regexp"
	"strings"
)

var (
	libRule  = regexp.MustCompile(`\A[a-z0-9_-]+\z`)
	pathRule = regexp.MustCompile(`\A(?:[\w:]+)(?:(?:\.|#|\s)(?:\w+))?\z`)
	modRule  = regexp.MustCompile(`\A\w+\z`)
)

type Query struct {
	Library string
	Types   []string
	Symbol  string
}

// 1: library Symbol
// 2: library Type Symbol
// 1: library Type.Symbol
// 1: library Type#Symbol
// 1: library Type::Symbol
// 2: library Type::Symbol Symbol
func ParseQuery(args []string) (*Query, error) {
	lib := "crystal"

	if len(args) > 1 && libRule.MatchString(args[0]) {
		lib = args[0]
		args = args[1:]
	}

	str := strings.Join(args, " ")
	if !pathRule.MatchString(str) {
		return nil, errors.New("invalid module or type path")
	}

	s, err := parseSymbol(str)
	if err != nil {
		return nil, err
	}

	t, err := parseTypes(s[0])
	if err != nil {
		return nil, err
	}

	return &Query{Library: lib, Types: t, Symbol: s[len(s)-1]}, nil
}

func parseSymbol(s string) ([]string, error) {
	parts := strings.Split(s, ".")
	if len(parts) == 1 {
		parts = strings.Split(parts[0], "#")
	}

	if len(parts) == 1 {
		parts = strings.Split(parts[0], " ")
	}

	if len(parts) > 2 {
		return nil, errors.New("invalid symbol path")
	}

	return parts, nil
}

func parseTypes(s string) ([]string, error) {
	parts := strings.Split(s, "::")
	for _, p := range parts {
		if !modRule.MatchString(p) {
			return nil, errors.New("invalid module or type path")
		}
	}

	return parts, nil
}
