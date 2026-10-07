# frozen_string_literal: true

source 'https://rubygems.org'

group :test do
  gem 'simplecov', require: nil
end

# RuboCop 1.x needs Ruby 2.7; the code is linted on a current Ruby
if Gem::Requirement.new('>= 2.7').satisfied_by?(Gem::Version.new(RUBY_VERSION))
  gem 'rubocop', '~> 1.80', require: false
end

gemspec
