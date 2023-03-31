package env

import (
	"os"
	"path/filepath"
)

var cache string
var lib string

func CacheDir() string {
	return cache
}

func LibDir() string {
	return lib
}

func init() {
	root, err := os.UserHomeDir()
	if err != nil {
		panic(err)
	}

	cache = filepath.Join(root, "docr", "cache")
	lib = filepath.Join(root, "docr", "libraries")
}
