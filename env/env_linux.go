//go:build darwin || linux
// +build darwin linux

package env

import (
	"os"
	"path/filepath"
)

func CacheDir() string {
	p := os.Getenv("XDG_CACHE_HOME")
	if p == "" {
		p, _ = filepath.Abs("~/.config")
	}
	return filepath.Join(p, "docr")
}

func LibraryDir() string {
	p := os.Getenv("XDG_DATA_HOME")
	if p == "" {
		p, _ = filepath.Abs("~/.local/share")
	}
	return filepath.Join(p, "docr")
}
