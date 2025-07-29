# KopsAI - Intelligent Operations Agent

> A Ruby-based intelligent operations agent for automating DevOps tasks, system monitoring, and incident response

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruby Version](https://img.shields.io/badge/ruby-3.0+-red.svg)](https://www.ruby-lang.org/)

## 🎯 Overview

KopsAI is an intelligent operations agent that helps DevOps engineers automate daily tasks, quickly respond to issues, and improve efficiency. It can be gradually evolved into a "universal operations assistant" with support for multiple plugin functions, DSL and command-line interactions.

## ✨ Features

- **System Monitoring**: Check CPU, memory, disk, and service status
- **Remote Execution**: Execute commands on remote servers via SSH
- **Kubernetes Integration**: Query cluster status, pods, and resources
- **AI-Powered Analysis**: Integrate with GPT for intelligent suggestions
- **Log Analysis**: Automatically collect and analyze logs
- **Notification System**: Support for DingTalk, Feishu, Telegram, and webhooks
- **Task Automation**: DSL-based task description and execution
- **Plugin Architecture**: Extensible plugin system

## 🚀 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/example/kops_ai.git
cd kops_ai

# Install dependencies
bundle install

# Make CLI executable
chmod +x bin/kops
```

### Configuration

Create a configuration file `config/kops.yml`:

```yaml
# Logging configuration
log_level: "info"
service_name: "kops-ai"

# OpenAI GPT configuration
openai_api_key: "${OPENAI_API_KEY}"
openai_model: "gpt-4"

# Prometheus configuration
prometheus_url: "${PROMETHEUS_URL}"

# Jenkins configuration
jenkins_url: "${JENKINS_URL}"
jenkins_username: "${JENKINS_USERNAME}"
jenkins_token: "${JENKINS_TOKEN}"

# Kubernetes configuration
k8s_config_path: "${KUBECONFIG}"

# Notification configuration
notification_webhook: "${NOTIFICATION_WEBHOOK}"
```

### Basic Usage

```bash
# Check system resources
kops check system

# Execute command via SSH
kops ssh exec --host 10.0.1.23 --command "df -h"

# Get Kubernetes pod logs
kops k8s --action logs --namespace prod --pod api-server --tail 100

# Analyze log with GPT
kops gpt analyze-log --log-file logs/nginx.log

# Run a task file
kops run --file tasks/memory_check.yml
```

## 📋 CLI Commands

### System Operations

```bash
# Check system resources
kops check system                    # All resources
kops check cpu                      # CPU only
kops check memory                   # Memory only
kops check disk                     # Disk only
kops check services                 # Services only
```

### SSH Operations

```bash
# Execute command on remote host
kops ssh exec --host 10.0.1.23 --command "df -h"

# With authentication
kops ssh exec --host 10.0.1.23 --command "systemctl status nginx" \
  --username admin --key-path ~/.ssh/id_rsa
```

### Kubernetes Operations

```bash
# List pods
kops k8s --action pods --namespace production

# List nodes
kops k8s --action nodes

# Get pod logs
kops k8s --action logs --namespace prod --pod api-server --tail 100

# Get cluster status
kops k8s --action status
```

### AI-Powered Analysis

```bash
# Analyze log file
kops gpt analyze-log --log-file logs/nginx.log

# Get fix suggestions
kops gpt suggest-fix --issue "Service is not responding"

# Explain command
kops gpt explain-command --command "kubectl get pods -n production"

# Generate script
kops gpt generate-script --task "Monitor disk usage and alert if over 90%"
```

### Log Analysis

```bash
# Analyze log patterns
kops log analyze --log-file logs/app.log

# Search logs
kops log search --log-file logs/app.log --query "ERROR" --lines 50

# Extract errors
kops log extract-errors --log-file logs/app.log --hours 24
```

### Notifications

```bash
# Send webhook notification
kops notify --platform webhook --message "System check completed"

# Send DingTalk notification
kops notify --platform dingtalk --message "Alert: High CPU usage" --level warning

# Send Telegram notification
kops notify --platform telegram --message "Deployment successful"
```

### Task Automation

```bash
# Run YAML task
kops run --file tasks/memory_check.yml

# Run Ruby DSL task
kops run --file tasks/k8s_monitor.rb
```

## 🧩 Plugin System

KopsAI uses a plugin-based architecture. Available plugins:

| Plugin | Description | Status |
|--------|-------------|--------|
| `system_check` | System resource monitoring | ✅ |
| `ssh_remote` | SSH remote execution | ✅ |
| `k8s_agent` | Kubernetes operations | ✅ |
| `prometheus_agent` | Prometheus metrics query | ✅ |
| `jenkins_agent` | Jenkins CI/CD integration | ✅ |
| `log_agent` | Log analysis and processing | ✅ |
| `gpt_support` | OpenAI GPT integration | ✅ |
| `notifier` | Multi-platform notifications | ✅ |

### Plugin Status

```bash
# List all plugins
kops plugins
```

## 📝 DSL Examples

### YAML Task Definition

```yaml
name: "Memory Check and Restart"
description: "Check memory usage and restart service if over threshold"

tasks:
  - type: "system_check"
    check_type: "memory"
    name: "Check memory usage"

  - type: "ssh"
    host: "10.0.1.23"
    command: "df -h"
    username: "admin"
    name: "Check disk usage on remote host"

  - type: "notify"
    platform: "webhook"
    message: "Memory check completed"
    level: "info"
    name: "Send notification"
```

### Ruby DSL

```ruby
task "K8sMonitor" do
  # Check cluster status
  cluster_status = k8s("status")
  puts "Cluster status: #{cluster_status}"

  # Get pods in production namespace
  pods = k8s("pods", namespace: "production")
  puts "Found #{pods.length} pods in production"

  # Check for failed pods
  failed_pods = pods.select { |pod| pod[:status] == "Failed" }

  if failed_pods.any?
    notify("Found #{failed_pods.length} failed pods in production", level: "warning")
  end
end
```

## 🔧 Configuration

### Environment Variables

```bash
# OpenAI
export OPENAI_API_KEY="your-api-key"

# Prometheus
export PROMETHEUS_URL="http://prometheus:9090"

# Jenkins
export JENKINS_URL="http://jenkins:8080"
export JENKINS_USERNAME="admin"
export JENKINS_TOKEN="your-token"

# Kubernetes
export KUBECONFIG="~/.kube/config"

# Notifications
export NOTIFICATION_WEBHOOK="https://hooks.slack.com/..."
export DINGTALK_WEBHOOK="https://oapi.dingtalk.com/..."
export TELEGRAM_BOT_TOKEN="your-bot-token"
export TELEGRAM_CHAT_ID="your-chat-id"
```

### Configuration File

The configuration file supports environment variable substitution:

```yaml
openai_api_key: "${OPENAI_API_KEY}"
prometheus_url: "${PROMETHEUS_URL}"
```

## 🏗️ Architecture

```
kops_ai/
├── bin/
│   └── kops          # CLI entry point
├── lib/
│   ├── kops_ai/
│   │   ├── core/     # Core framework: Agent, Plugin, Logger
│   │   ├── plugins/  # Plugins: ssh, system_check, k8s, jenkins, ...
│   │   ├── dsl/      # Task DSL
│   │   └── utils/    # Utilities: logging, formatting, scheduling
│   └── kops_ai.rb    # Main entry point
├── tasks/            # Example task YAML/DSL
├── config/           # Configuration files
└── README.md
```

## 🧪 Testing

```bash
# Run tests
bundle exec rspec

# Run with coverage
COVERAGE=true bundle exec rspec
```

## 📦 Development

### Building the Gem

```bash
# Build the gem
gem build kops_ai.gemspec

# Install locally
gem install kops_ai-0.1.0.gem
```

### Adding New Plugins

1. Create a new plugin class in `lib/kops_ai/plugins/`
2. Inherit from `Core::Plugin`
3. Implement the `execute` method
4. Register the plugin in `Core::Agent`

Example:

```ruby
module KopsAI
  module Plugins
    class MyPlugin < Core::Plugin
      def initialize
        super(
          name: "my_plugin",
          description: "My custom plugin",
          version: "1.0.0"
        )
      end

      def execute(action, **options)
        # Plugin implementation
      end
    end
  end
end
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Thor](https://github.com/rails/thor) - CLI framework
- [dry-rb](https://dry-rb.org/) - Ruby libraries
- [TTY](https://ttytoolkit.org/) - Terminal toolkit
- [OpenAI](https://openai.com/) - GPT integration

---

**KopsAI** - Making DevOps operations intelligent and automated! 🚀
