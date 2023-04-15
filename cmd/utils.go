package cmd

import (
	"fmt"
	"strings"
)

var ansiEncode = strings.NewReplacer("$B", "\033[34m", "$R", "\033[0m", "$S", "\033[1m")

func noArgs(args []string) error {
	if len(args) != 0 {
		return fmt.Errorf("expected no arguments but was given %d", len(args))
	}
	return nil
}

func rangeArgs(min, max int, args []string) error {
	if len(args) < min {
		return fmt.Errorf("expected at least %d arguments; got %d", min, len(args))
	}

	if len(args) > max {
		return fmt.Errorf("expected between %d and %d arguments; got %d", min, max, len(args))
	}

	return nil
}

func splitLines(s string) []string {
	a := strings.Split(s, "\n")
	var r []string
	for _, i := range a {
		if len(i) != 0 {
			r = append(r, i)
		}
	}
	return r
}
