# FireflyServer

Restarts a web server when watched files or directories are changed. Useful for rails applications the cache classes in development. The server runs in the foreground for easy logging and debugger output.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'firefly_server'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install firefly_server

## Usage

Create script `bin/firefly_server`

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "firefly_server"

server = FireflyServer.new.configure do |config|
  rails_root = File.expand_path("../..",  __FILE__)
  # file watcher
  config.watch_paths = %w[ app lib config vendor db/schemas bin ].map do |rails_dir|
    "#{rails_root}/#{rails_dir}"
  end
  config.ignore_paths = %w[ app/views app/emails ].map do |rails_dir|
    "#{rails_root}/#{rails_dir}"
  end
  # server
  config.start_server = "rails server -p 8080 -b 0.0.0.0"
  config.stop_server  = "pkill -INT -f 'puma'"
  config.pid_file     = "#{rails_root}/tmp/pids/server.pid"
end

server.start!
```

Make script executable: `chmod 700 bin/firefly_server`

Start server: `./bin/firefly_server`

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
