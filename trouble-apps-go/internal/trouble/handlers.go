package trouble

import (
	"bytes"
	"encoding/base64"
	"io"
	"net/http"

	"sprint3-app/internal/logging/log"
)

func GetRoot() func(w http.ResponseWriter, r *http.Request) {
	// base64 is used to prevent the string from being detected by 'grep' or 'strings'
	data, err := base64.StdEncoding.DecodeString("RkxBRzogV0hPSVNST01BUEFWTE9WCg==")
	if err != nil {
		log.Fatal().Err(err).Msg("BUG: Failed to decode data")
	}

	return func(w http.ResponseWriter, r *http.Request) {
		var err error
		responseReader := bytes.NewReader(data)
		emptyReader := bytes.NewReader([]byte{})

		for name, values := range r.Header {
			// Loop over all values for the name.
			for _, value := range values {
				log.Info().Msgf("Responding to request, header are: %s %s", name, value)
			}
		}
		// Connection close is used by nginx reverse proxy
		if r.Header.Get("Connection") == "close" {
			_, err = io.Copy(w, responseReader)
		} else {
			_, err = io.Copy(w, emptyReader)
		}

		if err != nil {
			log.Error().Err(err).Msg("Failed to respond to request")
		}
	}
}
