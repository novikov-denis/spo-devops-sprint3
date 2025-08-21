package main

import (
	"os"

	"sprint3-app/internal/echo"
	"sprint3-app/internal/logging"
)

func main() {
	if os.Getenv("DEBUG") != "" {
		logging.LogLevel("DEBUG")
	} else {
		logging.LogLevel("INFO")
	}

	server := echo.NewServer(":8080")
	os.Exit(server.StartWithExitCode())
}
