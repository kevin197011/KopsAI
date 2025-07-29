# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Kubernetes monitoring task using Ruby DSL

task 'K8sMonitor' do
  # Check cluster status
  cluster_status = k8s('status')
  puts "Cluster status: #{cluster_status}"

  # Get pods in production namespace
  pods = k8s('pods', namespace: 'production')
  puts "Found #{pods.length} pods in production"

  # Check for failed pods
  failed_pods = pods.select { |pod| pod[:status] == 'Failed' }

  if failed_pods.any?
    notify("Found #{failed_pods.length} failed pods in production", level: 'warning')

    failed_pods.each do |pod|
      logs = k8s('logs', namespace: 'production', pod: pod[:name], tail: 50)
      puts "Logs for #{pod[:name]}: #{logs[:logs]}"
    end
  end

  # Check system resources
  system_status = check('system')
  memory_usage = system_status[:memory][:usage_percent]

  notify("Memory usage is high: #{memory_usage}%", level: 'warning') if memory_usage > 85
end
