package cmd

import (
	"os/exec"
	"strings"

	"github.com/devnote-dev/docr/env"
	"github.com/devnote-dev/docr/log"
	"github.com/spf13/cobra"
)

var updateCommand = &cobra.Command{
	Use: "update",
	Run: func(cmd *cobra.Command, args []string) {
		log.Configure(cmd)
		if err := noArgs(args); err != nil {
			log.Error(err)
			cmd.HelpFunc()(cmd, args)
			return
		}

		if err := exec.Command("git", "version").Run(); err != nil {
			log.Error("could not find git executable (git version failed)")
			log.Error("git is required for this operation")
			log.Debugf("%v", err)
			return
		}

		libs, err := env.GetLibraries()
		if err != nil {
			libs = make(map[string][]string)
		}

		var ver string
		versions, ok := libs["crystal"]
		if ok && len(versions) != 0 {
			ver = versions[len(versions)-1]
		} else {
			log.Info("no crystal library docs imported")
			log.Info("searching for crystal...")

			out, err := exec.Command("crystal", "version").Output()
			if err != nil {
				log.Warn("could not find crystal executable (crystal version failed)")
				log.Info("importing latest crystal version docs")
			} else {
				s := strings.SplitN(string(out), " ", 3)
				ver = s[1]
				log.Info("found crystal version %s", ver)
			}
		}

		updateCrystal(ver)
		// TODO: cache import sources
		// delete(libs, "crystal")
	},
}

func updateCrystal(version string) {
	ver, err := env.GetCrystalVersions()
	if err != nil {
		log.Error("failed to get available crystal versions:")
		log.Error(err)
		return
	}

	for _, v := range ver {
		if v.Name == version {
			if v.Name == version {
				goto fetch
			}
		}
	}

	log.Warn("docs for crystal version %s is not available", version)
	version = ""

fetch:
	if version == "" {
		version = ver[1].Name
		log.Info("using crystal version %s", version)
	}

	if err := env.ImportCrystalVersion(version); err != nil {
		log.Errorf("failed to import documentation for crystal:")
		log.Error(err)
	}
	log.Info("imported crystal version %s", version)
}
