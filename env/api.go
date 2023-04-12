package env

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
)

type Version struct {
	Name string `json:"name"`
	URL  string `json:"url"`
}

func GetCrystalVersions() ([]*Version, error) {
	path := filepath.Join(lib, "crystal", "versions.json")
	if !exists(path) {
		if err := ImportCrystalVersions(); err != nil {
			return nil, err
		}
		return GetCrystalVersions()
	}

	buf, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var ver struct {
		Versions []*Version `json:"versions"`
	}
	if err := json.Unmarshal(buf, &ver); err != nil {
		return nil, err
	}

	return ver.Versions, nil
}

func ImportCrystalVersions() error {
	req, _ := http.NewRequest("GET", "https://crystal-lang.org/api/versions.json", nil)
	req.Header.Set("Accept", "application/json")
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}

	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("received non-ok http status: %d", res.StatusCode)
	}

	path := filepath.Join(lib, "crystal", "versions.json")
	dest, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0o666)
	if err != nil {
		return err
	}

	defer dest.Close()
	defer res.Body.Close()

	io.Copy(dest, res.Body)
	return nil
}

func ImportCrystalVersion(s string) error {
	ver, err := GetCrystalVersions()
	if err != nil {
		return err
	}

	var t *Version
	for _, v := range ver {
		if v.Name == s {
			t = v
			break
		}
	}

	if t == nil {
		return fmt.Errorf("version %s not found", s)
	}

	req, _ := http.NewRequest("GET", fmt.Sprintf("https://crystal-lang.org%sindex.json", t.URL), nil)
	req.Header.Set("Accept", "application/json")
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}

	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("received non-ok http status: %d", res.StatusCode)
	}

	path := filepath.Join(lib, "crystal", t.Name, "index.json")
	dest, err := os.Open(path)
	if err != nil {
		return err
	}

	defer dest.Close()
	defer res.Body.Close()

	io.Copy(dest, res.Body)
	return nil
}
