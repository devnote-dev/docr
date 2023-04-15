$hash = & { git.exe rev-parse HEAD }
$hash = $hash.SubString(0, 8)
$date = Get-Date -Format "yyyy-MM-dd"

$env:GOOS = "windows"
go.exe build -ldflags "-X github.com/devnote-dev/docr/cmd.Build=$hash -X github.com/devnote-dev/docr/cmd.Date=$date" -o build\docr.exe
