package cmd

import (
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/charmbracelet/glamour"
	"github.com/devnote-dev/docr/env"
	"github.com/devnote-dev/docr/log"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"
)

var libraryCommand = &cobra.Command{
	Use: "library command [arguments] [options]",
}

var libraryListCommand = &cobra.Command{
	Use: "list [options]",
	Run: func(cmd *cobra.Command, _ []string) {
		log.Configure(cmd)
		libraries, err := env.GetLibraries()
		if err != nil {
			log.Error("failed to get libraries:")
			log.Error(err)
			return
		}

		if len(libraries) == 0 {
			log.Error("no libraries have been installed")
			return
		}

		builder := strings.Builder{}
		for name, versions := range libraries {
			builder.WriteString(name)
			builder.WriteString("\n|\n")

			if len(versions) > 1 {
				for _, v := range versions[:1] {
					fmt.Fprintf(&builder, "|———— v%s\n", v)
				}
			}

			fmt.Fprintf(&builder, "'———— v%s\n", versions[len(versions)-1])
		}

		fmt.Println(builder.String())
	},
}

var libraryAboutCommand = &cobra.Command{
	Use: "about name [version]",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			return
		}
		log.Configure(cmd)

		name := args[0]
		var version string
		if len(args) > 1 {
			version = args[1]
		} else {
			ver, err := env.GetLibraryVersions(name)
			if err != nil {
				log.Error("failed to get library versions:")
				log.Error(err)
				return
			}

			version = ver[len(ver)-1]
		}

		buf, err := os.ReadFile(filepath.Join(env.LibraryDir(), name, version, "README.md"))
		if err != nil {
			if os.IsNotExist(err) {
				log.Errorf("library %s version %s has no README", name, version)
			} else {
				log.Error(err)
			}
			return
		}

		// policy := bluemonday.StrictPolicy().AllowElements("a", "code")
		term, _ := glamour.NewTermRenderer(
			glamour.WithAutoStyle(),
		)

		out, err := term.Render(string(buf))
		if err != nil {
			log.Errorf("failed to render library %s README:", name)
			log.Error(err)
			return
		}

		fmt.Print(out)
	},
}

var libraryAddCommand = &cobra.Command{
	Use: "add name source [version]",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) < 2 {
			cmd.Help()
			return
		}
		log.Configure(cmd)

		if args[0] == "crystal" {
			addCrystalLibrary(args[1])
		} else {
			ver := "latest"
			if len(args) > 2 {
				ver = args[2]
			}
			addExternalLibrary(args[0], ver, args[1])
		}
	},
}

func addCrystalLibrary(version string) {
	if version == "latest" || version == "nightly" {
		log.Info("importing %s crystal version", version)
	} else {
		log.Info("importing crystal version %s", version)
	}

	if version != "" {
		ver, err := env.GetLibraryVersions("crystal")
		if err != nil {
			log.Error("failed to get crystal library versions:")
			log.Error(err)
			return
		}

		for _, v := range ver {
			if v == version {
				log.Errorf("crystal version %s is already imported", v)
				log.Error("did you mean to run 'docr library update'?")
				return
			}
		}
	}

	log.Info("fetching available versions...")
	vers, err := env.GetCrystalVersions()
	if err != nil {
		log.Error("failed to get available crystal versions:")
		log.Error(err)
		return
	}

	if version == "latest" {
		version = vers[1].Name
		log.Info("using latest crystal: %s", version)
	}

	for _, v := range vers {
		if v.Name == version {
			goto fetch
		}
	}

	log.Errorf("crystal version %s not found", version)

fetch:
	if err := env.ImportCrystalVersion(version); err != nil {
		log.Errorf("failed to import documentation for crystal:")
		log.Error(err)
	}
	log.Info("imported crystal version %s", version)
}

func addExternalLibrary(name, version, source string) {
	if version == "latest" {
		log.Info("importing latest %s version", name)
	} else {
		log.Info("importing %s version %s", name, version)
	}

	u, err := url.Parse(source)
	if err != nil {
		log.Error(err)
		return
	}

	if u.Scheme == "" {
		u.Scheme = "https"
	}
	log.Debugf("url: %s", u.String())

	cache := filepath.Join(env.CacheDir(), name)
	if err := env.EnsureDirectory(cache); err != nil {
		log.Error(err)
		return
	}

	defer func() {
		log.Debugf("clearing: %s", cache)
		_ = os.RemoveAll(cache)
	}()

	log.Info("cloning into %s...", u.String())
	if err := clone(u.String(), version, cache); err != nil {
		log.Error(err)
		return
	}

	log.Info("installing dependencies...")
	log.Debug("exec: shards install --without-development")

	proc := exec.Command("shards", "install", "--without-development")
	proc.Dir = cache
	out, err := proc.Output()
	if err != nil {
		log.Errorf("failed to install library %s dependencies:", name)
		log.Error(out)
		return
	}

	log.Info("getting shard information...")
	shard, err := extractShard(cache)
	if err != nil {
		log.Error("failed to extract shard information:")
		log.Error(err)
		return
	}

	if shard.Name != name {
		log.Error("cannot verify shard: names do not match")
		log.Errorf("expected %s; got %s", name, shard.Name)
		return
	}

	if version == "latest" {
		version = shard.Version
	} else {
		if shard.Version != version {
			log.Error("cannot verify shard: versions do not match")
			log.Errorf("expected %s; got %s", version, shard.Version)
			return
		}
	}

	if _, err := env.GetLibrary(name, version); err == nil {
		log.Errorf("library %s version %s is already imported", name, version)
		return
	}

	lib := filepath.Join(env.LibraryDir(), name, version)
	log.Info("building documentation...")
	log.Debugf("exec: crystal docs -o %s", lib)

	proc = exec.Command("crystal", "docs", "-o", lib)
	proc.Dir = cache
	out, err = proc.Output()
	if err != nil {
		log.Error("failed to build docs:")
		log.Error(string(out))
		return
	}

	read := filepath.Join(env.CacheDir(), name, "README.md")
	log.Info("finalizing...")
	log.Debugf("read: %s", read)
	if exists(read) {
		_ = os.Rename(read, filepath.Join(env.LibraryDir(), name, version, "README.md"))
	}

	log.Info("imported %s version %s", name, version)
}

func clone(source, version, dest string) error {
	args := []string{"clone", source}
	if version != "" {
		args = append(args, "--branch", version)
	}
	args = append(args, dest)

	log.Debugf("exec: %v", args)
	err := exec.Command("git", args...).Run()
	if err == nil {
		return nil
	}

	if version == "" {
		return fmt.Errorf("failed to clone %s", source)
	}

	args[2] = "--tag"
	log.Debugf("exec: %v", args)
	err = exec.Command("git", args...).Run()
	if err == nil {
		return nil
	}

	args = append(args[:2], dest)
	log.Debugf("exec: %v", args)
	return exec.Command("git", args...).Run()
}

type shardDef struct {
	Name    string `yaml:"name"`
	Version string `yaml:"version"`
}

func extractShard(p string) (*shardDef, error) {
	p = filepath.Join(p, "shard.yml")
	log.Debugf("shard path: %s", p)

	buf, err := os.ReadFile(p)
	if err != nil {
		return nil, err
	}

	var s shardDef
	if err := yaml.Unmarshal(buf, &s); err != nil {
		return nil, err
	}

	return &s, nil
}

var libraryRemoveCommand = &cobra.Command{
	Use: "remove name [version]",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			return
		}
		log.Configure(cmd)

		var err error
		name := args[0]
		version := ""
		if len(args) > 1 {
			version = args[1]
		}

		if version == "" {
			err = env.RemoveLibrary(name)
		} else {
			err = env.RemoveLibraryVersion(name, version)
		}

		if err != nil {
			log.Error("failed to remove library:")
			log.Error(err)
		}
	},
}

func init() {
	libraryCommand.AddCommand(libraryListCommand)
	libraryCommand.AddCommand(libraryAboutCommand)
	libraryCommand.AddCommand(libraryAddCommand)
	libraryCommand.AddCommand(libraryRemoveCommand)
}
