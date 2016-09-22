# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dacom/version'

Gem::Specification.new do |s|
  s.name = "dacom"
  s.version = Dacom::VERSION
  s.authors = ["costajob"]
  s.email = ["costajob@gmail.com"]
  s.summary = %q{A Ruby port of the Dacom (LGU+) XPay client library}
  s.homepage = "https://github.com/costajob/dacom"
  s.license = "MIT"
  s.required_ruby_version = ">= 1.8.7"

  s.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir = "exe"
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency "json", "~> 1.8"
  s.add_development_dependency "bundler", "~> 1.11"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "minitest", "~> 5.0"
  s.add_development_dependency "rr", "~> 1.2"
end
