# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Gem::Specification.new do |spec|
  spec.name = "kops_ai"
  spec.version = "0.1.0"
  spec.authors = ["kk"]
  spec.email = ["kk@example.com"]

  spec.summary = "KopsAI - Intelligent Operations Agent"
  spec.description = "A Ruby-based intelligent operations agent for automating DevOps tasks, system monitoring, and incident response"
  spec.homepage = "https://github.com/example/kops_ai"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{bin,lib}/**/*") + %w[README.md LICENSE]
  spec.bindir = "bin"
  spec.executables = ["kops"]
  spec.require_paths = ["lib"]

  # Core dependencies
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "dry-struct", "~> 1.6"
  spec.add_dependency "dry-types", "~> 1.7"
  spec.add_dependency "net-ssh", "~> 7.0"
  spec.add_dependency "kubeclient", "~> 4.9"
  spec.add_dependency "ruby-openai", "~> 6.0"
  spec.add_dependency "httpx", "~> 1.1"
  spec.add_dependency "rufus-scheduler", "~> 3.8"
  spec.add_dependency "yaml", "~> 0.2"
  spec.add_dependency "json", "~> 2.6"
  spec.add_dependency "colorize", "~> 1.1"
  spec.add_dependency "tty-table", "~> 0.12"
  spec.add_dependency "tty-progressbar", "~> 0.18"
  spec.add_dependency "tty-prompt", "~> 0.23"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 2.20"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "vcr", "~> 6.1"
end
