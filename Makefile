# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

.PHONY: help install test build clean lint

# Default target
help:
	@echo "KopsAI - Intelligent Operations Agent"
	@echo ""
	@echo "Available targets:"
	@echo "  install    - Install dependencies"
	@echo "  test       - Run tests"
	@echo "  build      - Build the gem"
	@echo "  clean      - Clean build artifacts"
	@echo "  lint       - Run code linting"
	@echo "  setup      - Setup development environment"
	@echo "  version    - Show version"

# Install dependencies
install:
	bundle install

# Run tests
test:
	bundle exec rspec

# Run tests with coverage
test-coverage:
	COVERAGE=true bundle exec rspec

# Build the gem
build:
	gem build kops_ai.gemspec

# Clean build artifacts
clean:
	rm -f kops_ai-*.gem
	rm -rf coverage/

# Run code linting
lint:
	bundle exec rubocop

# Setup development environment
setup: install
	chmod +x bin/kops
	@echo "Development environment setup complete!"

# Show version
version:
	@echo "KopsAI v$(shell ruby -e "require './lib/kops_ai/version'; puts KopsAI::VERSION")"

# Install gem locally
install-local: build
	gem install kops_ai-*.gem

# Uninstall gem
uninstall:
	gem uninstall kops_ai

# Run CLI help
help-cli:
	./bin/kops help

# Example commands
example-system-check:
	./bin/kops check system

example-plugins:
	./bin/kops plugins

example-version:
	./bin/kops version