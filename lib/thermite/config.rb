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

require 'rbconfig'
require 'thermite/semver'
require 'tomlrb'

module Thermite
  #
  # Configuration for building, packaging and loading a Rust-based Ruby extension.
  #
  # Every value that Thermite reads from the outside world (task options, `Cargo.toml`, environment
  # variables and `RbConfig`) is read here, so that the other Thermite classes only need to be
  # handed a `Config` object.
  #
  class Config
    #
    # The default git tag regular expression (semantic versioning format).
    #
    DEFAULT_TAG_REGEX = /^(#{Thermite::SemVer::VERSION})$/.freeze

    #
    # Options that locate `Cargo.toml`, and therefore cannot be overridden by it.
    #
    CARGO_LOCATION_OPTIONS = %i[cargo_project_path cargo_workspace_member].freeze

    #
    # Creates a new configuration object.
    #
    # @param options [Hash] the same as the {Thermite::Tasks#initialize} parameter.
    # @param env [#[], #fetch, #key?] environment variables. Defaults to `ENV`.
    # @param rbconfig [Hash] Ruby build configuration. Defaults to `RbConfig::CONFIG`.
    #
    # `env` and `rbconfig` are positional rather than keyword parameters, so that
    # `Config.new(cargo_project_path: 'rust')` keeps treating the hash as `options`.
    #
    def initialize(options = {}, env = ENV, rbconfig = RbConfig::CONFIG)
      @task_options = options
      @env = env
      @rbconfig = rbconfig
    end

    #
    # The task options, with the values from the `package.metadata.thermite` section of
    # `Cargo.toml` taking precedence (except for {CARGO_LOCATION_OPTIONS}).
    #
    def options
      @options ||= @task_options.merge(overridable_toml_config)
    end

    #
    # Location to emit debug output, if not `nil`. Defaults to `nil`.
    #
    def debug_filename
      @env['THERMITE_DEBUG_FILENAME']
    end

    #
    # The name (or path) of the `cargo` executable. Can be set via the `CARGO` environment variable.
    #
    def cargo_executable_name
      @env.fetch('CARGO', 'cargo')
    end

    #
    # The Ruby interpreter that Rust build scripts (e.g., Rutie's) should build against. Can be set
    # via the `RUBY` environment variable. Defaults to the currently running interpreter.
    #
    def ruby_executable
      @env.fetch('RUBY') do
        File.join(@rbconfig['bindir'], "#{@rbconfig['ruby_install_name']}#{@rbconfig['EXEEXT']}")
      end
    end

    #
    # The Cargo profile to build with. Can be set via the `CARGO_PROFILE` environment variable.
    # Defaults to `release`.
    #
    def cargo_profile
      @env.fetch('CARGO_PROFILE', 'release')
    end

    #
    # Whether the `optional_rust_extension` option is set.
    #
    def optional_rust_extension?
      options.fetch(:optional_rust_extension, false) ? true : false
    end

    #
    # Whether the `github_releases` option is set.
    #
    def github_releases?
      options.fetch(:github_releases, false) ? true : false
    end

    #
    # The `github_release_type` option. Defaults to `'cargo'`.
    #
    def github_release_type
      options.fetch(:github_release_type, 'cargo')
    end

    #
    # The `git_tag_format` option. Defaults to `'v%s'`.
    #
    def git_tag_format
      options.fetch(:git_tag_format, 'v%s')
    end

    #
    # The format (as a regular expression) that git tags containing Rust binary
    # tarballs are supposed to match. Defaults to `DEFAULT_TAG_REGEX`.
    #
    def git_tag_regex
      @git_tag_regex ||= begin
        pattern = options[:git_tag_regex]
        pattern ? Regexp.new(pattern) : DEFAULT_TAG_REGEX
      end
    end

    #
    # The interpolation-formatted string used to construct the download URI for the pre-built
    # native extension. Can be set via the `THERMITE_BINARY_URI_FORMAT` environment variable, or a
    # `binary_uri_format` option.
    #
    def binary_uri_format
      @env['THERMITE_BINARY_URI_FORMAT'] || options[:binary_uri_format] || false
    end

    #
    # Whether the host is a Windows platform.
    #
    def windows?
      host_os = @rbconfig['host_os']
      Gem::WIN_PATTERNS.any? { |pattern| pattern.match?(host_os) }
    end

    #
    # Whether the target is macOS.
    #
    def darwin?
      target_os.start_with?('darwin')
    end

    #
    # The file extension of the compiled shared Rust library.
    #
    def shared_ext
      if dlext == 'bundle'
        'dylib'
      elsif windows?
        'dll'
      else
        dlext
      end
    end

    #
    # The major and minor version of the Ruby interpreter that's currently running.
    #
    def ruby_version
      major, minor = @rbconfig['ruby_version'].split('.')
      "ruby#{major}#{minor}"
    end

    #
    # Alias for `RbConfig::CONFIG['target_cpu']`.
    #
    def target_arch
      @rbconfig['target_cpu']
    end

    #
    # Alias for `RbConfig::CONFIG['target_os']`.
    #
    def target_os
      @rbconfig['target_os']
    end

    #
    # The name of the library compiled by Rust.
    #
    # Due to the way that Cargo works, all hyphens in library names are replaced with underscores.
    #
    def library_name
      lib = toml.fetch(:lib, {})
      name = lib[:name] || toml.fetch(:package, {})[:name]
      name&.tr('-', '_')
    end

    #
    # The basename of the shared library built by Cargo.
    #
    def cargo_shared_library
      filename = "#{library_name}.#{shared_ext}"
      windows? ? filename : "lib#{filename}"
    end

    #
    # The basename of the Rust shared library, as installed in the {#ruby_extension_path}.
    #
    def shared_library
      "#{library_name}.so"
    end

    #
    # Return the basename of the tarball generated by the `thermite:tarball` Rake task, given a
    # package `version`.
    #
    def tarball_filename(version)
      static = static_extension? ? '-static' : ''

      "#{library_name}-#{version}-#{ruby_version}-#{target_os}-#{target_arch}#{static}.tar.gz"
    end

    #
    # The top-level directory of the Ruby project. Defaults to the current working directory.
    #
    def ruby_toplevel_dir
      options.fetch(:ruby_project_path) { Dir.pwd }
    end

    #
    # Generate a path relative to {#ruby_toplevel_dir}, given the `path_components` that are passed
    # to `File.join`.
    #
    def ruby_path(*path_components)
      File.join(ruby_toplevel_dir, *path_components)
    end

    #
    # Absolute path to the shared libruby.
    #
    def libruby_path
      File.join(@rbconfig['libdir'], @rbconfig['LIBRUBY_SO'])
    end

    #
    # The top-level directory of the Cargo project. Defaults to the current working directory.
    #
    def rust_toplevel_dir
      @task_options.fetch(:cargo_project_path) { Dir.pwd }
    end

    #
    # Generate a path relative to {#rust_toplevel_dir}, given the `path_components` that are
    # passed to `File.join`.
    #
    def rust_path(*path_components)
      File.join(rust_toplevel_dir, *path_components)
    end

    #
    # Generate a path relative to the `CARGO_TARGET_DIR` environment variable, or
    # {#rust_toplevel_dir}/target if that is not set.
    #
    def cargo_target_path(target, *path_components)
      target_base = @env.fetch('CARGO_TARGET_DIR') { rust_path('target') }
      File.join(target_base, target, *path_components)
    end

    #
    # If run in a multi-crate environment, the Cargo workspace member that contains the
    # Ruby extension.
    #
    def cargo_workspace_member
      @task_options[:cargo_workspace_member]
    end

    #
    # The absolute path to the `Cargo.toml` file. The path depends on the existence of the
    # {#cargo_workspace_member} configuration option.
    #
    def cargo_toml_path
      rust_path(*[cargo_workspace_member, 'Cargo.toml'].compact)
    end

    #
    # The relative directory where the Rust shared library resides, in the context of the Ruby
    # project.
    #
    def ruby_extension_dir
      options.fetch(:ruby_extension_dir, 'lib')
    end

    #
    # Path to the Rust shared library in the context of the Ruby project.
    #
    def ruby_extension_path
      ruby_path(ruby_extension_dir, shared_library)
    end

    #
    # Parsed TOML object (courtesy of `tomlrb`).
    #
    def toml
      @toml ||= Tomlrb.load_file(cargo_toml_path, symbolize_keys: true)
    end

    #
    # Alias to the crate version specified in the TOML file.
    #
    def crate_version
      toml[:package][:version]
    end

    #
    # The URL of the crate's repository, as specified in the TOML file.
    #
    # @raise [KeyError] if the crate does not specify a repository.
    #
    def repository_uri
      repository = toml.fetch(:package, {})[:repository]
      raise KeyError, 'No repository found in Cargo.toml' unless repository

      repository
    end

    #
    # The Thermite-specific config from the TOML file.
    #
    def toml_config
      toml.dig(:package, :metadata, :thermite) || {}
    end

    #
    # Linker flags for libruby.
    #
    def dynamic_linker_flags
      @rbconfig['DLDFLAGS'].strip
    end

    #
    # Whether to use a statically linked extension.
    #
    def static_extension?
      @env.key?('RUBY_STATIC') || @rbconfig['ENABLE_SHARED'] == 'no'
    end

    private

    def dlext
      @rbconfig['DLEXT']
    end

    def overridable_toml_config
      toml_config.reject { |key, _| CARGO_LOCATION_OPTIONS.include?(key) }
    end
  end
end
