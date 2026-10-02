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
require 'thermite/package'

module Thermite
  class PackageTest < Minitest::Test
    include Thermite::ConfigHelper

    #
    # Records which {Thermite::InstallNameTool} steps were run. Like the real tool, it changes the
    # library it prepares for packaging.
    #
    class FakeInstallNameTool
      attr_reader :steps

      def initialize
        @steps = []
      end

      def before_packaging(library_path)
        @steps << :before_packaging
        File.write(library_path, "#{File.read(library_path)} (packaged)")
      end

      def after_unpacking
        @steps << :after_unpacking
      end
    end

    def test_build
      config = build_config(options: { ruby_project_path: stub_project_dir })

      assert_equal config.tarball_filename('4.5.6'), File.basename(build_tarball(config))
    end

    def test_build_leaves_installed_library_unchanged
      config = build_config(options: { ruby_project_path: stub_project_dir })
      tarball_path = build_tarball(config)

      assert_equal 'some extension', File.read(config.ruby_extension_path)
      FileUtils.rm_f(config.ruby_extension_path)
      File.open(tarball_path, 'rb') { |f| package(config).unpack(f) }
      assert_equal 'some extension (packaged)', File.read(config.ruby_extension_path)
    end

    def test_build_and_install
      config = build_config(options: { ruby_project_path: stub_project_dir })
      tarball_path = build_tarball(config)
      FileUtils.rm_f(config.ruby_extension_path)

      assert_file_created(config.ruby_extension_path) do
        install_from_another_directory(config, tarball_path)
      end

      assert_equal 'some extension (packaged)', File.read(config.ruby_extension_path)
      assert_equal %i[before_packaging after_unpacking], install_name_tool.steps
      assert_equal ['Unpacking file: lib/test_crate.so'], logger.messages
    end

    def test_unpack_does_not_adjust_install_name
      config = build_config(options: { ruby_project_path: stub_project_dir })
      tarball_path = build_tarball(config)

      File.open(tarball_path, 'rb') { |f| package(config).unpack(f) }

      assert_equal %i[before_packaging], install_name_tool.steps
    end

    private

    def package(config)
      Thermite::Package.new(config, logger: logger, install_name_tool: install_name_tool)
    end

    def install_name_tool
      @install_name_tool ||= FakeInstallNameTool.new
    end

    def logger
      @logger ||= FakeLogger.new
    end

    #
    # Builds a tarball of a fake extension in the Ruby project directory, returning its path.
    #
    def build_tarball(config)
      File.write(config.ruby_extension_path, 'some extension')
      Dir.chdir(config.ruby_toplevel_dir) do
        File.expand_path(package(config).build)
      end
    end

    #
    # This simulates having an extension build via `install/Rakefile` instead of the top-level
    # Rakefile.
    #
    def install_from_another_directory(config, tarball_path)
      Dir.chdir(File.join(config.ruby_toplevel_dir, 'lib')) do
        File.open(tarball_path, 'rb') { |f| package(config).install(f) }
      end
    end

    def stub_project_dir
      dir = Dir.mktmpdir('thermite_project')
      temp_dirs << dir
      Dir.mkdir(File.join(dir, 'lib'))

      dir
    end

    def assert_file_created(filename)
      refute File.exist?(filename), "File '#{filename}' already exists."
      yield
      assert File.exist?(filename), "File '#{filename}' does not exist."
    end
  end
end
