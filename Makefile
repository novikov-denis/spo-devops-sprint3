.ONESHELL:
SHELL = /bin/bash

GOBASE=$(shell pwd)
GOBIN=$(GOBASE)/ansible/files/bin
SOURCE=$(GOBASE)/trouble-apps-go
ECHO_SOURCE=$(GOBASE)/trouble-apps-go/cmd/echo
WATCHER_SOURCE=$(GOBASE)/trouble-apps-go/cmd/watcher
TROUBLE_SOURCE=$(GOBASE)/trouble-apps-go/cmd/trouble
CGO_ENABLED=1

default: vagrant-up

# Legacy alias for backwards compatibility
.PHONY: build
build: vagrant-up

.PHONY: clean
clean:
	@echo "  >  Cleaning build artifacts..."
	@rm -rf $(GOBIN)
	@rm -f storage-disk.vdi console.log

# Vagrant commands
.PHONY: vagrant-up
vagrant-up: compile
	@echo "  >  Starting Vagrant VM..."
	@vagrant up

.PHONY: vagrant-provision
vagrant-provision:
	@echo "  >  Provisioning Vagrant VM..."
	@vagrant provision

.PHONY: vagrant-ssh
vagrant-ssh:
	@echo "  >  Connecting to Vagrant VM..."
	@vagrant ssh

.PHONY: vagrant-destroy
vagrant-destroy:
	@echo "  >  Destroying Vagrant VM..."
	@vagrant destroy -f
	@rm -f storage-disk.vdi console.log

.PHONY: vagrant-rebuild
vagrant-rebuild: vagrant-destroy vagrant-up

.PHONY: vagrant-status
vagrant-status:
	@vagrant status

compile: go-clean go-tidy go-vet go-build

go-clean:
	@echo "  >  Cleaning build cache"
	@cd "$(SOURCE)"; GOBIN="$(GOBIN)" go clean
	@rm -rf "$(GOBIN)"

go-tidy:
	@echo "  >  Update modules..."
	@cd "$(SOURCE)"; go mod tidy

go-vet:
	@echo "  >  Vet project..."
	@cd "$(SOURCE)"; go vet ./...

go-build:
	@echo "  >  Building binaries..."
	@cd "$(ECHO_SOURCE)"; GOOS=linux GOARCH=amd64 go build -o "$(GOBIN)/echo" main.go
	@cd "$(WATCHER_SOURCE)"; GOOS=linux GOARCH=amd64 go build -o "$(GOBIN)/watcher" main.go
	@cd "$(TROUBLE_SOURCE)"; GOOS=linux GOARCH=amd64 go build -o "$(GOBIN)/trouble" main.go
