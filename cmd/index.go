package cmd

import (
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/devnote-dev/docr/env"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"
)

var indexCommand = &cobra.Command{
	Use: "index command [arguments] [options]",
	Run: func(*cobra.Command, []string) {},
}

var indexListCommand = &cobra.Command{
	Use: "list [options]",
	Run: func(*cobra.Command, []string) {
		libraries, err := env.GetLibraries()
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}

		if len(libraries) == 0 {
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

var indexGetCommand = &cobra.Command{
	Use: "get name source [version]",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) != 2 {
			return
		}

		name := args[0]
		src := args[1]
		version := ""
		if len(args) > 2 {
			version = args[2]
		}

		if name == "crystal" {
			if version != "" {
				ver, err := env.GetLibraryVersions("crystal")
				if err != nil {
					fmt.Fprintln(os.Stderr, err)
					return
				}

				for _, v := range ver {
					if v == version {
						fmt.Fprintf(os.Stderr, "crystal version %s is already downloaded\n", v)
						// did you mean to run 'docr index update crystal'?
						return
					}
				}

				// TODO
			}
		}

		u, err := url.ParseRequestURI(src)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}

		cache := filepath.Join(env.CacheDir(), name)
		if err := env.EnsureDirectory(cache); err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}
		defer os.RemoveAll(cache)

		if err := clone(u.String(), version, cache); err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}

		proc := exec.Command("shards", "install", "--without-development")
		proc.Dir = cache
		out, err := proc.Output()
		if err != nil {
			fmt.Fprintf(os.Stderr, "failed to install dependencies:\n%s\n", out)
			return
		}

		shard, err := extractShard(cache)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}

		if shard.Name != name {
			fmt.Fprintln(os.Stderr, "shard name does not match")
			return
		}

		if version == "" {
			version = shard.Version
		} else {
			if shard.Version != version {
				fmt.Fprintln(os.Stderr, "shard version does not match")
				return
			}
		}

		lib := filepath.Join(env.LibDir(), name, version)
		proc = exec.Command("crystal", "docs", "-o", lib)
		proc.Dir = cache
		out, err = proc.Output()
		if err != nil {
			fmt.Fprintf(os.Stderr, "failed to build docs:\n%s\n", out)
			return
		}
	},
}

var indexRemoveCommand = &cobra.Command{
	Use: "remove name [version]",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			return
		}

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
			fmt.Fprintln(os.Stderr, err)
		}
	},
}

func init() {
	indexCommand.AddCommand(indexListCommand)
	indexCommand.AddCommand(indexGetCommand)
	indexCommand.AddCommand(indexRemoveCommand)
}

func clone(source, version, dest string) error {
	args := []string{"clone", source}
	if version != "" {
		args = append(args, "--branch", version)
	}
	args = append(args, dest)

	err := exec.Command("git", args...).Run()
	if err == nil {
		return nil
	}

	if version != "" {
		args[2] = "--tag"
	}
	err = exec.Command("git", args...).Run()
	if err == nil {
		return nil
	}

	args = append(args[:2], dest)
	return exec.Command("git", args...).Run()
}

type shardDef struct {
	Name    string `yaml:"name"`
	Version string `yaml:"version"`
}

func extractShard(p string) (*shardDef, error) {
	p = filepath.Join(p, "shard.yml")
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
