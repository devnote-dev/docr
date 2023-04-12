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

func Debug(v string) {
	if withDebug {
		fmt.Println(v)
	}
}

func Debugf(v string, a ...any) {
	if withDebug {
		fmt.Printf("%s\n", fmt.Sprintf(v, a...))
	}
}

func DebugError(e error) {
	if withDebug {
		fmt.Println(e)
	}
}

func Info(v string) {
	if withColor {
		fmt.Print("\033[34mInfo\033[0m: ")
	} else {
		fmt.Print("Info: ")
	}
	fmt.Println(v)
}

func Error(v any) {
	if withColor {
		fmt.Print("\033[31mError\033[0m: ")
	} else {
		fmt.Print("Error: ")
	}
	fmt.Fprintln(os.Stderr, v)
}

func Errorf(v string, a ...any) {
	if withColor {
		fmt.Print("\033[31mError\033[0m: ")
	} else {
		fmt.Print("Error: ")
	}
	fmt.Fprintf(os.Stderr, "%s\n", fmt.Sprintf(v, a...))
}
