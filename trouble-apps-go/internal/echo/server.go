package echo

import (
	"bytes"
	"context"
	"encoding/base64"
	"io"
	"net"
	"sync"
	"syscall"

	"sprint3-app/internal/logging/log"
	"sprint3-app/internal/signals"
)

type Server struct {
	port     string
	listener net.Listener
}

func NewServer(port string) *Server {
	return &Server{
		port: port,
	}
}

func (s *Server) StartWithExitCode() int {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	log.Info().Msg("Start echo server")
	s.startListener()

	wg := sync.WaitGroup{}

	wg.Add(1)
	go func() {
		defer wg.Done()
		<-ctx.Done()
		log.Debug().Msg("Close server listener")
		if err := s.listener.Close(); err != nil {
			log.Fatal().Err(err).Msgf("Failed to close listener")
		}
	}()

	wg.Add(1)
	go func() {
		defer wg.Done()
		data, err := base64.StdEncoding.DecodeString("RkxBRzogSUdPUlRJVU5PVg==")
		if err != nil {
			log.Fatal().Err(err).Msg("BUG: Failed to decode data")
		}
		r := bytes.NewReader(data)
		for {
			conn, err := s.listener.Accept()
			if err != nil {
				log.Debug().Err(err).Msg("Stop to accept new client connections")
				return
			}

			go handleClient(r, conn)
		}
	}()

	sig := <-signals.Channel()

	log.Info().Msg("Stop echo server, wait for resources cleanup")
	cancel()
	wg.Wait()

	// Return success for Ctrl+C, otherwise will be restarted by systemd
	if sig == syscall.SIGINT {
		return 0
	}

	return 1
}

func (s *Server) startListener() {
	var err error
	s.listener, err = net.Listen("tcp", s.port)
	if err != nil {
		log.Fatal().Err(err).Msgf("Failed to start listener")
	}
}

func handleClient(r io.Reader, conn net.Conn) {
	defer func() {
		log.Debug().Msg("Close client connection")
		if err := conn.Close(); err != nil {
			log.Error().Err(err).Msg("Failed to close client connection")
		}
	}()
	log.Debug().Msgf("Handle client connection for %s", conn.RemoteAddr().String())
	if _, err := io.Copy(conn, r); err != nil {
		log.Error().Err(err).Msg("Failed to send data to client")
	}
}
