#!/bin/bash

GIT_HEAD=$(git rev-parse HEAD | head -c8)
GOOS=linux go build -ldflags "-X github.com/devnote-dev/docr/cmd.Build=$GIT_HEAD -X github.com/devnote-dev/docr/cmd.Date=$(date +%F)" -o build/docr
