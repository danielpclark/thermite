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

require 'test_helper'
require 'thermite/cargo'

module Thermite
  class CargoTest < Minitest::Test
    include Thermite::ConfigHelper

    #
    # Records the commands it is asked to run, and the directory they are run in.
    #
    class FakeShell
      attr_reader :commands

      def initialize
        @commands = []
      end

      def sh(*command)
        @commands << [Dir.pwd, command]
      end
    end

    def test_available
      assert cargo.available?
      refute cargo(executable: nil).available?
    end

    def test_run_in_rust_toplevel_dir_with_ruby_executable
      cargo.run('foo', 'bar')

      dir, command = shell.commands.first
      assert_equal File.realpath(default_config.rust_toplevel_dir), File.realpath(dir)
      assert_equal [{ 'RUBY' => '/opt/ruby/bin/ruby' }, '/opt/cargo-test/bin/cargo', 'foo', 'bar'],
                   command
    end

    def test_test
      cargo.test
      assert_equal [%w[test]], cargo_args
    end

    def test_test_sans_cargo
      cargo(executable: nil).test
      assert_empty shell.commands
    end

    def test_clean_with_workspace_member
      cargo(config: build_config(options: { cargo_workspace_member: 'foo/bar' })).clean
      assert_equal [%w[clean --manifest-path foo/bar/Cargo.toml]], cargo_args
    end

    def test_clean_sans_cargo
      cargo(executable: nil).clean
      assert_empty shell.commands
    end

    def test_build_debug
      cargo.build('debug')
      assert_equal [%w[rustc]], cargo_args
    end

    def test_build_release
      cargo.build('release')
      assert_equal [%w[rustc --release]], cargo_args
    end

    def test_build_with_workspace_member
      cargo(config: build_config(options: { cargo_workspace_member: 'foo/bar' })).build('debug')
      assert_equal [%w[rustc --manifest-path foo/bar/Cargo.toml]], cargo_args
    end

    def test_build_with_dynamic_linker_flags
      cargo(config: build_config(rbconfig: { 'DLDFLAGS' => 'foo bar' })).build('debug')
      assert_equal [['rustc', '--lib', '--', '-C', 'link-args=foo bar']], cargo_args
    end

    def test_build_with_dynamic_linker_flags_on_mingw
      config = build_config(rbconfig: { 'DLDFLAGS' => 'foo bar', 'target_os' => 'mingw32' })
      cargo(config: config).build('debug')
      assert_equal [%w[rustc]], cargo_args
    end

    def test_finds_cargo_executable_from_config
      Dir.mktmpdir do |dir|
        # On Windows, only files with an executable extension (e.g. `.exe`) are executable.
        executable = File.join(dir, "my-cargo#{RbConfig::CONFIG['EXEEXT']}")
        File.write(executable, '')
        File.chmod(0o755, executable)

        config = build_config(env: { 'CARGO' => executable })
        assert_equal executable, Thermite::Cargo.new(config).executable
      end
    end

    private

    def default_config
      @default_config ||= build_config
    end

    def shell
      @shell ||= FakeShell.new
    end

    def cargo(config: default_config, executable: '/opt/cargo-test/bin/cargo')
      Thermite::Cargo.new(config, executable: executable, shell: shell)
    end

    def cargo_args
      shell.commands.map { |_, command| command.drop(2) }
    end
  end
end
