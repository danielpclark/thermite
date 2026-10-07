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

module Thermite
  class ConfigTest < Minitest::Test
    include Thermite::ConfigHelper

    def test_debug_filename
      assert_nil build_config.debug_filename
      assert_equal 'foo', build_config(env: { 'THERMITE_DEBUG_FILENAME' => 'foo' }).debug_filename
    end

    def test_cargo_executable_name
      assert_equal 'cargo', build_config.cargo_executable_name
      config = build_config(env: { 'CARGO' => '/opt/cargo' })
      assert_equal '/opt/cargo', config.cargo_executable_name
    end

    def test_cargo_profile
      assert_equal 'release', build_config.cargo_profile
      assert_equal 'debug', build_config(env: { 'CARGO_PROFILE' => 'debug' }).cargo_profile
    end

    def test_ruby_executable
      assert_equal '/opt/ruby/bin/ruby', build_config.ruby_executable
      assert_equal 'C:/Ruby27/bin/ruby.exe',
                   build_config(rbconfig: { 'bindir' => 'C:/Ruby27/bin', 'EXEEXT' => '.exe' })
                     .ruby_executable
      config = build_config(env: { 'RUBY' => '/usr/bin/ruby2.7' })
      assert_equal '/usr/bin/ruby2.7', config.ruby_executable
    end

    def test_shared_ext_osx
      assert_equal 'dylib', build_config(rbconfig: { 'DLEXT' => 'bundle' }).shared_ext
    end

    def test_shared_ext_windows
      assert_equal 'dll', build_config(rbconfig: { 'host_os' => 'mingw32' }).shared_ext
    end

    def test_shared_ext_unix
      assert_equal 'foobar', build_config(rbconfig: { 'DLEXT' => 'foobar' }).shared_ext
    end

    def test_windows
      assert build_config(rbconfig: { 'host_os' => 'mswin64_140' }).windows?
      refute build_config.windows?
    end

    def test_darwin
      assert build_config(rbconfig: { 'target_os' => 'darwin19' }).darwin?
      refute build_config.darwin?
    end

    def test_ruby_version
      assert_equal 'ruby32', build_config(rbconfig: { 'ruby_version' => '3.2.0' }).ruby_version
    end

    def test_library_name_from_cargo_lib
      config = build_config(cargo_toml: package_toml("[lib]\nname = \"foobar\""))
      assert_equal 'foobar', config.library_name
    end

    def test_library_name_from_cargo_package
      assert_equal 'barbaz', build_config(cargo_toml: package_toml).library_name
    end

    def test_library_name_from_cargo_lib_has_no_hyphens
      config = build_config(cargo_toml: package_toml("[lib]\nname = \"foo-bar\"", name: 'bar-baz'))
      assert_equal 'foo_bar', config.library_name
    end

    def test_library_name_from_cargo_package_has_no_hyphens
      assert_equal 'bar_baz', build_config(cargo_toml: package_toml(name: 'bar-baz')).library_name
    end

    def test_shared_library
      assert_equal 'barbaz.so', build_config(cargo_toml: package_toml).shared_library
    end

    def test_shared_library_windows
      config = build_config(cargo_toml: package_toml, rbconfig: { 'host_os' => 'mingw32' })
      assert_equal 'barbaz.so', config.shared_library
    end

    def test_cargo_shared_library
      config = build_config(cargo_toml: package_toml, rbconfig: { 'DLEXT' => 'ext' })
      assert_equal 'libbarbaz.ext', config.cargo_shared_library
    end

    def test_cargo_shared_library_windows
      config = build_config(cargo_toml: package_toml, rbconfig: { 'host_os' => 'mingw32' })
      assert_equal 'barbaz.dll', config.cargo_shared_library
    end

    def test_version_defaults_to_crate_version
      assert_equal '4.5.6', build_config(cargo_toml: package_toml).version
    end

    def test_version_option
      config = build_config(options: { version: '7.8.9' }, cargo_toml: package_toml)

      assert_equal '7.8.9', config.version
      assert_equal '4.5.6', config.crate_version
    end

    def test_version_from_toml_config
      toml = package_toml("[package.metadata.thermite]\nversion = \"7.8.9\"\n")

      assert_equal '7.8.9', build_config(cargo_toml: toml).version
    end

    def test_tarball_filename
      assert_equal 'barbaz-0.1.2-ruby12-z80-c64.tar.gz',
                   tarball_config.tarball_filename('0.1.2')
    end

    def test_tarball_filename_with_static_extension
      assert_equal 'barbaz-0.1.2-ruby12-z80-c64-static.tar.gz',
                   tarball_config(env: { 'RUBY_STATIC' => '1' }).tarball_filename('0.1.2')
    end

    def test_default_ruby_toplevel_dir
      dir = cargo_project
      Dir.chdir(dir) do
        assert_equal Dir.pwd, Thermite::Config.new({}, {}, {}).ruby_toplevel_dir
      end
    end

    def test_ruby_toplevel_dir
      config = build_config(options: { ruby_project_path: '/tmp/barbaz' })
      assert_equal '/tmp/barbaz', config.ruby_toplevel_dir
    end

    def test_ruby_path
      config = build_config(options: { ruby_project_path: '/tmp/foobar' })
      assert_equal '/tmp/foobar/baz/quux', config.ruby_path('baz', 'quux')
    end

    def test_ruby_extension_path
      config = build_config(options: { ruby_project_path: '/tmp/foobar' }, cargo_toml: package_toml)
      assert_equal '/tmp/foobar/lib/barbaz.so', config.ruby_extension_path
    end

    def test_ruby_extension_path_with_custom_extension_dir
      options = { ruby_project_path: '/tmp/foobar', ruby_extension_dir: 'lib/ext' }
      config = build_config(options: options, cargo_toml: package_toml)
      assert_equal '/tmp/foobar/lib/ext/barbaz.so', config.ruby_extension_path
    end

    def test_libruby_path
      assert_equal '/opt/ruby/lib/libruby.so.2.7', build_config.libruby_path
    end

    def test_default_rust_toplevel_dir
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          assert_equal Dir.pwd, Thermite::Config.new.rust_toplevel_dir
        end
      end
    end

    def test_rust_toplevel_dir
      config = build_config(options: { cargo_project_path: '/tmp/barbaz' })
      assert_equal '/tmp/barbaz', config.rust_toplevel_dir
    end

    def test_rust_path
      config = build_config(options: { cargo_project_path: '/tmp/foobar' })
      assert_equal '/tmp/foobar/baz/quux', config.rust_path('baz', 'quux')
    end

    def test_cargo_target_path_with_env_var
      config = build_config(env: { 'CARGO_TARGET_DIR' => 'foo' })
      assert_equal File.join('foo', 'debug', 'bar'), config.cargo_target_path('debug', 'bar')
    end

    def test_cargo_target_path_without_env_var
      config = build_config(options: { cargo_project_path: '/tmp/foobar' })
      assert_equal File.join('/tmp/foobar', 'target', 'debug', 'bar'),
                   config.cargo_target_path('debug', 'bar')
    end

    def test_cargo_toml_path_with_workspace_member
      options = { cargo_project_path: '/tmp/foobar', cargo_workspace_member: 'baz' }
      config = build_config(options: options)
      assert_equal '/tmp/foobar/baz/Cargo.toml', config.cargo_toml_path
    end

    def test_default_git_tag_regex
      assert_equal described_class::DEFAULT_TAG_REGEX, build_config.git_tag_regex
    end

    def test_git_tag_regex
      assert_equal(/abc(\d)/, build_config(options: { git_tag_regex: 'abc(\d)' }).git_tag_regex)
    end

    def test_toml
      expected = {
        package: {
          name: 'fixture',
          metadata: {
            thermite: {
              github_releases: true
            }
          }
        }
      }
      config = build_config(options: { cargo_project_path: fixtures_path('config') })
      assert_equal expected, config.toml
    end

    def test_default_toml_config
      assert_equal({}, build_config.toml_config)
    end

    def test_toml_config
      expected = { github_releases: true }
      config = build_config(options: { cargo_project_path: fixtures_path('config') })
      assert_equal expected, config.toml_config
    end

    def test_options_are_overridden_by_toml_config
      dir = cargo_project(package_toml(<<~TOML))
        [package.metadata.thermite]
        github_releases = true
        cargo_workspace_member = "ignored"
      TOML
      options = { cargo_project_path: dir, github_releases: false, git_tag_format: 'v%s' }
      config = build_config(options: options)

      assert_equal({ cargo_project_path: dir, github_releases: true, git_tag_format: 'v%s' },
                   config.options)
      assert config.github_releases?
      assert_nil config.cargo_workspace_member
    end

    def test_option_defaults
      config = build_config

      refute config.github_releases?
      refute config.optional_rust_extension?
      assert_equal 'cargo', config.github_release_type
      assert_equal 'v%s', config.git_tag_format
      assert_equal 'lib', config.ruby_extension_dir
      refute config.binary_uri_format
    end

    def test_binary_uri_format
      config = build_config(options: { binary_uri_format: 'option' })
      assert_equal 'option', config.binary_uri_format
      config = build_config(options: { binary_uri_format: 'option' },
                            env: { 'THERMITE_BINARY_URI_FORMAT' => 'env' })
      assert_equal 'env', config.binary_uri_format
    end

    def test_crate_version
      assert_equal '4.5.6', build_config.crate_version
    end

    def test_repository_uri
      config = build_config(cargo_toml: package_toml(repository: 'https://github.com/user/project'))
      assert_equal 'https://github.com/user/project', config.repository_uri
    end

    def test_repository_uri_when_missing
      assert_raises(KeyError) { build_config.repository_uri }
    end

    def test_dynamic_linker_flags
      config = build_config(rbconfig: { 'DLDFLAGS' => ' -L/foo ' })
      assert_equal '-L/foo', config.dynamic_linker_flags
    end

    def test_static_extension_sans_env_var
      refute build_config.static_extension?
      assert build_config(rbconfig: { 'ENABLE_SHARED' => 'no' }).static_extension?
    end

    def test_static_extension_with_env_var
      assert build_config(env: { 'RUBY_STATIC' => '1' }).static_extension?
    end

    private

    def described_class
      Thermite::Config
    end

    def package_toml(extra = '', name: 'barbaz', repository: nil)
      toml = +"[package]\nname = \"#{name}\"\nversion = \"4.5.6\"\n"
      toml << "repository = \"#{repository}\"\n" if repository
      toml << "\n#{extra}\n"
    end

    def tarball_config(env: {})
      rbconfig = { 'ruby_version' => '1.2.0', 'target_os' => 'z80', 'target_cpu' => 'c64' }
      build_config(cargo_toml: package_toml, env: env, rbconfig: rbconfig)
    end
  end
end
