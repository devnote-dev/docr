//go:build windows
// +build windows

package env

import (
	"os"
	"path/filepath"
)

func CacheDir() string {
	return filepath.Join(os.Getenv("LOCALAPPDATA"), "docr")
}

func LibraryDir() string {
	return filepath.Join(os.Getenv("APPDATA"), "docr")
}
