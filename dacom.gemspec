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
  s.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir = "bin"
  s.executables = %w[]
  s.require_paths = ["lib"]
  s.license = "MIT"
  s.required_ruby_version = ">= 2.2.2"
  
  s.add_development_dependency "bundler", "~> 1.15"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "minitest", "~> 5.0"
end
