NAME := nginx_exporter
VERSION := v0.1.0
LDFLAGS := -ldflags "-X main.Version=$(VERSION)"

help: ## Shows this help text
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

dev: ## Builds dev binary
	go build $(LDFLAGS)

build: ## Builds binary for all supported platforms
	@rm -rf build/
	@gox -ldflags "-X main.Version=$(VERSION)" \
	-osarch="darwin/amd64" \
	-os="linux" \
	-os="windows" \
	-output "build/{{.Dir}}_$(VERSION)_{{.OS}}_{{.Arch}}/$(NAME)" \
	./...

install: ## Locally installs dev binary
	go install $(LDFLAGS)

deps: ## Installs dev dependencies
	go get -u -v github.com/c4milo/github-release
	go get -u -v github.com/mitchellh/gox
	go get -u -v github.com/kardianos/govendor

dist: build ## Generates distributable artifacts
	$(eval FILES := $(shell ls build))
	@rm -rf dist && mkdir dist
	@for f in $(FILES); do \
		(cd $(shell pwd)/build/$$f && tar -cvzf ../../dist/$$f.tar.gz *); \
		(cd $(shell pwd)/dist && shasum -a 512 $$f.tar.gz > $$f.sha512); \
		echo $$f; \
	done

release: dist ## Pushes up distributable artifacts to Github Releases
	@latest_tag=$$(git describe --tags `git rev-list --tags --max-count=1`); \
	comparison="$$latest_tag..HEAD"; \
	if [ -z "$$latest_tag" ]; then comparison=""; fi; \
	changelog=$$(git log $$comparison --oneline --no-merges); \
	github-release c4milo/$(NAME) $(VERSION) "$$(git rev-parse --abbrev-ref HEAD)" "**Changelog**<br/>$$changelog" 'dist/*'; \
	git pull

clean: ## Runs go clean
	go clean $(LDFLAGS)

.PHONY: build dev clean dist install deps release
