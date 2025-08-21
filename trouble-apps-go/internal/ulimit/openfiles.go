package ulimit

import (
	"fmt"
	"os"

	"sprint3-app/internal/logging/log"
)

const maxOpenFiles = 4097

func OpenFiles(uid string) error {
	var fds [maxOpenFiles]*os.File
	for i := 0; i < maxOpenFiles; i++ {
		fd, err := os.OpenFile(fmt.Sprintf("/run/user/%s/file", uid), os.O_RDWR|os.O_CREATE, 0700)
		if err != nil {
			return err
		}
		fds[i] = fd
	}

	defer func(fds [maxOpenFiles]*os.File) {
		for _, fd := range fds {
			if fd.Close() != nil {
				log.Fatal().Msgf("Failed close file %s", fd.Name())
			}
		}
	}(fds)

	return nil
}
