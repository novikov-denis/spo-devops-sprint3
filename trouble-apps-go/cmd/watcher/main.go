package main

import (
	"sprint3-app/internal/logging/log"
	"sprint3-app/internal/lsof"
	"sprint3-app/internal/signals"
)

func main() {
	f := lsof.NewLockedFileOrDie("/locks/lockfile.lock")
	defer f.Unlock()
	if err := f.Lock(); err != nil {
		log.Fatal().Err(err).Msg("Failed to lock")
	}

	<-signals.Channel()
}
