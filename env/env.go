package env

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"

	"github.com/devnote-dev/docr/crystal"
)

const defaultPerms = fs.FileMode(os.O_CREATE | os.O_RDWR | os.O_TRUNC)

func EnsureDirectory(path string) error {
	if exists(path) {
		if err := os.RemoveAll(path); err != nil {
			return err
		}
	}

	return os.MkdirAll(path, defaultPerms)
}

func GetLibraries() (map[string][]string, error) {
	lib := LibraryDir()
	entries, err := os.ReadDir(lib)
	if err != nil {
		return nil, err
	}

	libraries := map[string][]string{}
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}

		inner, err := os.ReadDir(filepath.Join(lib, e.Name()))
		if err != nil {
			continue
		}

		var versions []string
		for _, i := range inner {
			if !i.IsDir() {
				continue
			}
			versions = append(versions, i.Name())
		}

		libraries[e.Name()] = versions
	}

	return libraries, nil
}

func GetLibraryVersions(name string) ([]string, error) {
	entries, err := os.ReadDir(filepath.Join(LibraryDir(), name))
	if err != nil {
		if os.IsNotExist(err) {
			return []string{}, nil
		}

		return nil, err
	}

	var versions []string
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		versions = append(versions, e.Name())
	}

	return versions, nil
}

func GetLibrary(name, version string) (*crystal.Type, error) {
	path := filepath.Join(LibraryDir(), name, version, "index.json")
	if !exists(path) {
		return nil, fmt.Errorf("could not find documentation for %s version %s", name, version)
	}

	buf, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var top crystal.TopLevel
	if err := json.Unmarshal(buf, &top); err != nil {
		return nil, err
	}

	return &top.Program, nil
}

func RemoveLibrary(name string) error {
	path := filepath.Join(LibraryDir(), name)
	if exists(path) {
		return os.RemoveAll(path)
	}

	return fmt.Errorf("library %s does not exist", name)
}

func RemoveLibraryVersion(name, version string) error {
	path := filepath.Join(LibraryDir(), name, version)
	if exists(path) {
		if err := os.RemoveAll(path); err != nil {
			return err
		}

		path = filepath.Dir(path)
		dir, err := os.ReadDir(path)
		if err != nil || len(dir) != 0 {
			return nil
		}

		return os.RemoveAll(path)
	}

	return fmt.Errorf("library %s version %s does not exist", name, version)
}

func exists(p string) bool {
	if _, err := os.Stat(p); err != nil {
		return false
	}

	return true
}
