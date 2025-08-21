package signals

import (
	"os"
	"os/signal"
	"syscall"
)

func Channel() <-chan os.Signal {
	sigChannel := make(chan os.Signal, 1)
	signal.Notify(sigChannel,
		syscall.SIGINT,
		syscall.SIGTERM,
	)

	return sigChannel
}
