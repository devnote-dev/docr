package cmd

import "fmt"

func exactArgs(n int, args []string) error {
	if len(args) != n {
		return fmt.Errorf("expected %d argument(s); got %d", n, len(args))
	}
	return nil
}

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
