require "firefly_server/version"
require "firefly_server/configuration"
require "firefly_server/file_watcher"

class FireflyServer
  attr_accessor(*%w[ configuration file_watcher ])

  def initialize(params = {})
    self.configuration = Configuration.new
    self.file_watcher = FileWatcher.new(configuration)
  end

  def configure
    yield(configuration)
    self
  end

  def process_exists?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end

  def start!
    server_pid = nil
    configuration.validate!
    # stop server if it is running
    %x(#{configuration.stop_server})
    # trap signals and exit
    configuration.exit_signals.each do |signal|
      Signal.trap(signal) do
        # attempt to stop server
        if server_pid && process_exists?(server_pid)
          puts "Stopping Server: #{configuration.stop_server}"
          %x(#{configuration.stop_server})
        end
        # reset shell in case of server crash messing with prompt (common byebug problem)
        if server_pid && process_exists?(server_pid)
          %x{reset}
          puts 'Server Stop Failed: Shell was "reset" to ensure access after possible crash'
        end
        puts "\rStopping Firefly Server"
        exit 130
      end
    end
    # file_watcher loop
    file_watcher.watch! do |files|
      puts "Ignored: #{files.ignored.join(", ")}"   if files.ignored?
      puts "Modified: #{files.modified.join(", ")}" if files.modified?
      puts "Added: #{files.added.join(", ")}"       if files.added?
      puts "Removed: #{files.removed.join(", ")}"   if files.removed?
      # stop server
      if files.modified? || files.added? || files.removed?
        puts "Stopping Server: #{configuration.stop_server}"
        %x(#{configuration.stop_server})
      end
    end
    # server loop
    restart_attempt = 0
    loop do
      # delete stale PID file
      File.delete(configuration.pid_file) if File.file?(configuration.pid_file)
      # start server
      puts "Starting Server: #{configuration.start_server}"
      # new fork will have nil initial pid
      server_pid = fork
      # new fork
      if server_pid == nil
        exec(configuration.start_server)
      else
        Process.wait(server_pid)
        server_pid_status = $? # Process.wait sets $? to pid status
      end
      # normal restart
      if server_pid_status.success?
        restart_attempt = 0
      # failed restart
      else
        restart_attempt += 1
        # throttle restart attempts to prevent high CPU usage
        if restart_attempt >= configuration.restart_attempt_throttle_threshold
          puts "Throttling restart attempts by sleeping #{configuration.restart_attempt_throttle_sleep} seconds"
          sleep(configuration.restart_attempt_throttle_sleep)
        end
      end
    end
  end
end
