# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'emeril/version'

Gem::Specification.new do |spec|
  spec.name          = "emeril"
  spec.version       = Emeril::VERSION
  spec.authors       = ["Fletcher Nichol"]
  spec.email         = ["fnichol@nichol.ca"]
  spec.description   = %q{Release Chef cookbooks}
  spec.summary       = spec.description
  spec.homepage      = "http://fnichol.github.io/emeril/"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.2'

  spec.add_dependency 'chef', '> 0.10.10'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'fakefs'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'webmock'

  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'countloc'

  # style and complexity libraries are tightly version pinned as newer releases
  # may introduce new and undesireable style choices which would be immediately
  # enforced in CI
  spec.add_development_dependency "finstyle",  "1.1.0"
  spec.add_development_dependency "cane",      "2.6.2"
end
