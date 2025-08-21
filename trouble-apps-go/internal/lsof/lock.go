package lsof

import (
	"fmt"
	"os"

	"github.com/gofrs/flock"

	"sprint3-app/internal/logging/log"
)

type File struct {
	fl *flock.Flock
}

func NewLockedFileOrDie(path string) *File {
	fd, err := os.OpenFile(path, os.O_RDONLY|os.O_CREATE, 0755)
	if err != nil {
		log.Fatal().Msg("Failed to start")
	}

	if err := fd.Close(); err != nil {
		log.Fatal().Err(err).Msg("Failed to close lock file")
	}

	return &File{fl: flock.New(path)}
}

func (f *File) Lock() error {
	ok, err := f.fl.TryLock()

	if err != nil || !ok {
		return fmt.Errorf("failed to lock %s", f.fl.String())
	}

	return nil
}

func (f *File) Unlock() {
	if err := f.fl.Unlock(); err != nil {
		log.Debug().Err(err).Msgf("Failed to unlock %s", f.fl.String())
	}
}
