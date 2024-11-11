# ==================================================================================== # 
# HELPERS
# ==================================================================================== #

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

# ==================================================================================== # 
# DEVELOPMENT
# ==================================================================================== #

## run/api: run the cmd/api application
.PHONY: run/web
run/web:
	go run ./cmd/web

# ==================================================================================== # 
# QUALITY CONTROL
# ==================================================================================== #

## audit: tidy dependencies and format, vet and test all code
.PHONY: audit 
audit: vendor
	@echo 'Tidying and verifying module dependencies...' go mod tidy
	go mod verify
	@echo 'Formatting code...'
	go fmt ./...
	@echo 'Vetting code...'
	go vet ./...
	staticcheck ./...
	@echo 'Running tests...'
	go test -race -vet=off ./...

.PHONY: vendor
vendor:
	@echo 'Tidying and verifying module dependencies...'
	go mod tidy
	go mod verify
	@echo 'Vendoring dependencies...'
	go mod vendor

# ==================================================================================== # 
# BUILD
# ==================================================================================== #

## build/api: build the cmd/api application
.PHONY: build/web
build/web: 
	@echo 'Building cmd/web...'
	go build -o=./bin/web ./cmd/web
	GOOS=linux GOARCH=amd64 go build -o=./bin/linux_amd64/web ./cmd/web