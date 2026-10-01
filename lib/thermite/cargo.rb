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

require 'rake/file_utils_ext'
require 'thermite/executable'

module Thermite
  #
  # Runs `cargo` commands for the Rust project described by a {Thermite::Config}.
  #
  class Cargo
    #
    # Message used when cargo is required but not found.
    #
    REQUIRED_MESSAGE = <<~MESSAGE
      ****
      Rust's Cargo is required to build this extension. Please install
      Rust and put it in the PATH, or set the CARGO environment variable appropriately.
      ****
    MESSAGE

    #
    # Message used when cargo is recommended but not found.
    #
    RECOMMENDED_MESSAGE = <<~MESSAGE
      ****
      Rust's Cargo is recommended (but not required) to build this extension. Please install
      Rust and put it in the PATH, or set the CARGO environment variable appropriately.
      ****
    MESSAGE

    #
    # The path to `cargo`, or `nil` if it was not found.
    #
    attr_reader :executable

    #
    # @param config [Thermite::Config]
    # @param executable [String, nil] the path to `cargo`. Defaults to searching the `PATH` for
    #                                 {Thermite::Config#cargo_executable_name}.
    # @param shell [#sh] runs commands. Defaults to Rake's `sh`, which respects Rake's verbosity
    #                    settings.
    #
    def initialize(config, executable: Executable.find(config.cargo_executable_name),
                   shell: Rake::FileUtilsExt)
      @config = config
      @executable = executable
      @shell = shell
    end

    #
    # Whether `cargo` was found.
    #
    def available?
      !@executable.nil?
    end

    #
    # Runs `cargo` with the given `args` in {Thermite::Config#rust_toplevel_dir}.
    #
    # The `RUBY` environment variable is set to {Thermite::Config#ruby_executable}, so that build
    # scripts which link to libruby (such as Rutie's) use the same Ruby that runs Thermite.
    #
    def run(*args)
      Dir.chdir(@config.rust_toplevel_dir) do
        @shell.sh({ 'RUBY' => @config.ruby_executable }, @executable, *args)
      end
    end

    #
    # Builds the Rust shared library via `cargo rustc`, given a Cargo profile (e.g., `release` or
    # `debug`).
    #
    def build(profile)
      args = ['rustc', *manifest_path_args]
      args << '--release' if profile == 'release'
      run(*args, *rustc_args)
    end

    #
    # Runs `cargo clean`, if `cargo` is available.
    #
    def clean
      run('clean', *manifest_path_args) if available?
    end

    #
    # Runs `cargo test`, if `cargo` is available.
    #
    def test
      run('test', *manifest_path_args) if available?
    end

    private

    #
    # If the `cargo_workspace_member` option is set, the `--manifest-path` argument to `cargo`.
    #
    def manifest_path_args
      return [] unless @config.cargo_workspace_member

      ['--manifest-path', File.join(@config.cargo_workspace_member, 'Cargo.toml')]
    end

    def rustc_args
      return [] if @config.dynamic_linker_flags.empty? || @config.target_os == 'mingw32'

      ['--lib', '--', '-C', "link-args=#{@config.dynamic_linker_flags}"]
    end
  end
end
