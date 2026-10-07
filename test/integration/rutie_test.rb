# frozen_string_literal: true
#
# Copyright (c) 2016 Mark Lee and contributors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
# OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'test_helper'
require 'thermite/package'
require 'thermite/debug_log'
require 'thermite/tasks'

module Thermite
  #
  # Builds, tests, packages and loads a real Rutie 0.13.1 extension with Thermite.
  #
  # Opt-in, since it needs Cargo, network access to crates.io and a Ruby that Rutie 0.13 supports
  # (3.2 to 3.4, built with `--enable-shared`):
  #
  #     THERMITE_RUTIE_INTEGRATION=1 rake test
  #
  class RutieIntegrationTest < Minitest::Test
    include Thermite::ConfigHelper

    RUTIE_RUBY_VERSIONS = Gem::Requirement.new('>= 3.2', '< 3.5')

    def setup
      skip 'Set THERMITE_RUTIE_INTEGRATION=1 to run' unless ENV['THERMITE_RUTIE_INTEGRATION']
      unless RUTIE_RUBY_VERSIONS.satisfied_by?(Gem::Version.new(RUBY_VERSION))
        skip "Rutie 0.13 does not support Ruby #{RUBY_VERSION}"
      end
      # Required only once the test runs: Fiddle is not a default gem since Ruby 4.0, which this
      # test skips.
      require 'thermite/fiddle'

      @original_application = Rake.application
      Rake.application = Rake::Application.new
    end

    def teardown
      Rake.application = @original_application if defined?(@original_application)
      super
    end

    def test_build_test_package_and_load
      project_dir = copy_fixture
      options = { cargo_project_path: project_dir, ruby_project_path: project_dir }
      tasks = Thermite::Tasks.new(options)

      Dir.chdir(project_dir) do
        %w[thermite:build thermite:test thermite:tarball].each { |name| Rake::Task[name].invoke }
      end

      # Packaging must leave the built library usable.
      assert_loads_extension(options)
      assert_tarball_installs(tasks.config, project_dir)
    end

    private

    def copy_fixture
      dir = Dir.mktmpdir('thermite_rutie')
      temp_dirs << dir
      FileUtils.cp_r(File.join(fixtures_path('rutie_extension'), '.'), dir)
      Dir.mkdir(File.join(dir, 'lib'))

      dir
    end

    def assert_loads_extension(options)
      Thermite::Fiddle.load_module('Init_rutie_thermite_example', options)

      assert_equal 'selppa', Object.const_get(:RutieThermiteExample).reverse('apples')
    end

    #
    # Installs the tarball into another project, as a gem install without Cargo would, and loads
    # the installed library.
    #
    def assert_tarball_installs(config, project_dir)
      install_dir = copy_fixture
      install_options = { cargo_project_path: install_dir, ruby_project_path: install_dir }
      install_config = Thermite::Config.new(install_options)
      tarball = File.join(project_dir, config.tarball_filename(config.version))
      package = Thermite::Package.new(install_config, logger: Thermite::DebugLog.new(nil))

      File.open(tarball, 'rb') { |tgz| package.install(tgz) }

      assert File.exist?(install_config.ruby_extension_path)
      assert_loads_extension(install_options)
    end
  end
end
