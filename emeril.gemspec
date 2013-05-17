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
  spec.homepage      = "https://github.com/fnichol/emeril"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.2'

  spec.add_dependency 'chef'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'guard-minitest'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'fakefs'

  spec.add_development_dependency 'cane'
  spec.add_development_dependency 'guard-cane'
  spec.add_development_dependency 'tailor'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'countloc'
end
