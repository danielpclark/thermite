# frozen_string_literal: true

require 'English'

Gem::Specification.new do |s|
  s.name        = 'thermite'
  s.version     = '0.13.0'
  s.summary     = 'Rake helpers for Rust+Ruby'
  s.description = 'A Rake-based helper for building and distributing Rust-based Ruby extensions'

  s.authors     = ['Mark Lee']
  s.email       = 'malept@users.noreply.github.com'
  s.homepage    = 'https://github.com/malept/thermite'
  s.license     = 'MIT'

  s.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  s.require_paths = %w[lib]

  s.required_ruby_version = '>= 2.5.0'

  s.add_runtime_dependency 'minitar', '~> 0.9'
  s.add_runtime_dependency 'rake', '>= 10'
  # REXML is a bundled (not default) gem since Ruby 3.0, so it must be declared to be loadable.
  s.add_runtime_dependency 'rexml', '~> 3.0'
  s.add_runtime_dependency 'tomlrb', '~> 2.0'
  s.add_development_dependency 'minitest', '~> 5.14'
  s.add_development_dependency 'rubocop', '~> 0.93.1'
  s.add_development_dependency 'yard', '~> 0.9'
end
