package env

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

var (
	cache string
	lib   string
)

func init() {
	root, err := os.UserHomeDir()
	if err != nil {
		panic(err)
	}

	cache = filepath.Join(root, "docr", "cache")
	lib = filepath.Join(root, "docr", "libraries")
}

func CacheDir() string {
	return cache
}

func LibDir() string {
	return lib
}

func GetLibraries() (map[string][]string, error) {
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
			if strings.HasSuffix(i.Name(), ".json") && i.Type().IsRegular() {
				versions = append(versions, i.Name())
			}
		}

		libraries[e.Name()] = versions
	}

	return libraries, nil
}

func GetLibraryVersions(name string) ([]string, error) {
	entries, err := os.ReadDir(filepath.Join(lib, name))
	if err != nil {
		if os.IsNotExist(err) {
			return nil, fmt.Errorf("documentation not available for %s", name)
		}

		return nil, err
	}

	var versions []string
	for _, e := range entries {
		if strings.HasSuffix(e.Name(), ".json") && e.Type().IsRegular() {
			versions = append(versions, e.Name())
		}
	}

	return versions, nil
}

func GetLibrary(name, version string) (string, error) {
	path := filepath.Join(lib, name, version+".json")
	if exists(path) {
		return path, nil
	}

	if exists(filepath.Join(lib, name)) {
		return "", fmt.Errorf("documentation not available for %s version %s", name, version)
	}

	return "", fmt.Errorf("could not find documentation for %s", name)
}

func CreateLibrary(name, version string, data []byte) (string, error) {
	if _, err := GetLibrary(name, version); err != nil {
		return "", fmt.Errorf("documentation for %s version %s already exists", name, version)
	}

	path := filepath.Join(lib, name)
	if err := os.MkdirAll(path, fs.FileMode(os.O_CREATE|os.O_RDWR|os.O_TRUNC)); err != nil {
		return "", err
	}

	path = filepath.Join(path, version+".json")
	file, err := os.Create(path)
	if err != nil {
		return "", err
	}

	defer file.Close()
	file.Write(data)

	return path, nil
}

func RemoveLibrary(name, version string) error {
	if _, err := GetLibrary(name, version); err != nil {
		return fmt.Errorf("documentation does not exist for %s version %s", name, version)
	}

	return os.Remove(filepath.Join(lib, name, version+".json"))
}

func exists(p string) bool {
	if _, err := os.Stat(p); err != nil {
		return false
	}

	return true
}
