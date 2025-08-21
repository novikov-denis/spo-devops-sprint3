package main

import (
	"net/http"
	"os/user"
	"sprint3-app/internal/lsof"
	"sprint3-app/internal/trouble"

	"sprint3-app/internal/logging/log"
	"sprint3-app/internal/ulimit"
)

func main() {
	// Get the current user.
	u, err := user.Current()
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to get current user")
	}

	// Prevent running as root
	if u.Name == "root" || u.Uid == "0" {
		log.Fatal().Msg("Failed to start, running as root?")
	}

	// Check current limits
	if err := ulimit.OpenFiles(u.Uid); err != nil {
		log.Fatal().Msg("Failed to start")
	}

	// Try to lock file
	f := lsof.NewLockedFileOrDie("/locks/lockfile.lock")
	defer f.Unlock()
	if err := f.Lock(); err != nil {
		log.Fatal().Msg("Failed to start")
	}

	// Start the server
	http.HandleFunc("/", trouble.GetRoot())
	if http.ListenAndServe("localhost:8080", nil) != http.ErrServerClosed {
		log.Fatal().Msg("Failed to start")
	}
}
