# frozen_string_literal: true
#
# Copyright (c) 2016, 2017 Mark Lee and contributors
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

begin
  require 'simplecov'
  SimpleCov.start do
    load_profile 'test_frameworks'
    add_filter 'lib/thermite/fiddle.rb'
    track_files 'lib/**/*.rb'
  end
rescue LoadError
  # Coverage is optional, e.g. when running the suite against an older Ruby without the gem.
  nil
end

require 'fileutils'
require 'minitest/autorun'
require 'tmpdir'
require 'thermite/config'

module Thermite
  #
  # Helpers for building {Thermite::Config} objects that do not depend on the machine running the
  # tests.
  #
  module ConfigHelper
    LINUX_RBCONFIG = {
      'bindir' => '/opt/ruby/bin',
      'DLDFLAGS' => '',
      'DLEXT' => 'so',
      'ENABLE_SHARED' => 'yes',
      'EXEEXT' => '',
      'host_os' => 'linux-gnu',
      'libdir' => '/opt/ruby/lib',
      'LIBRUBY_SO' => 'libruby.so.2.7',
      'ruby_install_name' => 'ruby',
      'ruby_version' => '2.7.0',
      'target_cpu' => 'x86_64',
      'target_os' => 'linux'
    }.freeze

    def fixtures_path(*components)
      File.join(File.dirname(__FILE__), 'fixtures', *components)
    end

    #
    # Creates a temporary Cargo project containing `cargo_toml`, and returns its path. It is
    # removed after the test.
    #
    def cargo_project(cargo_toml = "[package]\nname = \"test-crate\"\nversion = \"4.5.6\"\n")
      dir = Dir.mktmpdir('thermite_test')
      temp_dirs << dir
      File.write(File.join(dir, 'Cargo.toml'), cargo_toml)

      dir
    end

    #
    # A {Thermite::Config} for a temporary Cargo project (see {#cargo_project}), unless
    # `cargo_project_path` is specified.
    #
    def build_config(options: {}, env: {}, rbconfig: {}, cargo_toml: nil)
      options = { cargo_project_path: cargo_toml ? cargo_project(cargo_toml) : cargo_project }
                .merge(options)
      Thermite::Config.new(options, env, LINUX_RBCONFIG.merge(rbconfig))
    end

    def temp_dirs
      @temp_dirs ||= []
    end

    def teardown
      temp_dirs.each { |dir| FileUtils.rm_rf(dir) }
      super
    end
  end

  #
  # Records debug messages.
  #
  class FakeLogger
    attr_reader :messages

    def initialize
      @messages = []
    end

    def debug(msg)
      @messages << msg
    end
  end
end
