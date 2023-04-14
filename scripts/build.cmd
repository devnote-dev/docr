@ECHO OFF
SETLOCAL

FOR /F %%i IN ('git rev-parse HEAD') DO SET BUILD=%%i
SET GOOS=windows
go build -ldflags="-X github.com/devnote-dev/docr/cmd.Build=%BUILD%" -o build\docr.exe

ENDLOCAL
