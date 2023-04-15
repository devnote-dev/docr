package log

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var withColor, withDebug bool

func Configure(cmd *cobra.Command) {
	if term := os.Getenv("TERM"); term != "dumb" {
		if _, ok := os.LookupEnv("NO_COLOR"); !ok {
			if ok, _ := cmd.Flags().GetBool("no-color"); !ok {
				withColor = true
			}
		}
	}

	if ok, _ := cmd.Flags().GetBool("debug"); ok {
		withDebug = true
	}
}

func Debug(v any, a ...any) {
	if withDebug {
		if len(a) == 0 {
			fmt.Println(v)
		} else if s, ok := v.(string); ok {
			fmt.Printf("%s\n", fmt.Sprintf(s, a...))
		} else {
			fmt.Println(v)
		}
	}
}

func DebugError(e error) {
	if withDebug {
		fmt.Println(e)
	}
}

func Info(v string, a ...any) {
	if withColor {
		fmt.Print("\033[34m(i)\033[0m ")
	} else {
		fmt.Print("(i) ")
	}

	if len(a) == 0 {
		fmt.Println(v)
	} else {
		fmt.Printf("%s\n", fmt.Sprintf(v, a...))
	}
}

func Warn(v string, a ...any) {
	if withColor {
		fmt.Print("\033[33m(!)\033[0m ")
	} else {
		fmt.Print("(!) ")
	}

	if len(a) == 0 {
		fmt.Println(v)
	} else {
		fmt.Printf("%s\n", fmt.Sprintf(v, a...))
	}
}

func Error(v any, a ...any) {
	if withColor {
		fmt.Fprint(os.Stderr, "\033[31m(!)\033[0m ")
	} else {
		fmt.Fprint(os.Stderr, "(!) ")
	}

	// Go doesn't support this...
	// if len(a) != 0 && s, ok := v.(string); ok {

	if len(a) == 0 {
		fmt.Fprintln(os.Stderr, v)
	} else if s, ok := v.(string); ok {
		fmt.Fprintf(os.Stderr, "%s\n", fmt.Sprintf(s, a...))
	} else {
		fmt.Fprintln(os.Stderr, v)
	}
}
