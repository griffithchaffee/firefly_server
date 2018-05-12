# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "firefly_server/version"

Gem::Specification.new do |spec|
  spec.name          = "firefly_server"
  spec.version       = FireflyServer::VERSION
  spec.authors       = ["Griffith Chaffee"]
  spec.email         = ["griffithchaffee@gmail.com"]

  spec.summary       = %q(Restarts a web server when watched files or directories are changed.)
  spec.description   = %q(Restarts a web server when watched files or directories are changed. Useful for rails applications the cache classes in development.)
  spec.homepage      = "https://github.com/griffithchaffee/firefly_server"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "listen", "~> 3.1"
end
