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
require 'thermite/tasks'

module Thermite
  class TasksTest < Minitest::Test
    include Thermite::ConfigHelper

    def setup
      @original_application = Rake.application
      Rake.application = Rake::Application.new
    end

    def teardown
      Rake.application = @original_application
      super
    end

    def test_defines_tasks
      Thermite::Tasks.new(cargo_project_path: cargo_project)

      assert_equal %w[thermite:build thermite:clean thermite:tarball thermite:test],
                   Rake.application.tasks.map(&:name).sort
      assert_equal %w[thermite:build], Rake::Task['thermite:tarball'].prerequisites
    end

    def test_tasks_without_cargo
      config_options = { cargo_project_path: cargo_project, ruby_project_path: ruby_project,
                         optional_rust_extension: true }
      extension_path = nil

      _, err = without_cargo do
        capture_io do
          extension_path = Thermite::Tasks.new(config_options).config.ruby_extension_path
          File.write(extension_path, 'stale extension')
          invoke_tasks
        end
      end

      assert_equal Thermite::Cargo::RECOMMENDED_MESSAGE, err
      refute File.exist?(extension_path)
    end

    def test_options_include_toml_config
      dir = cargo_project(<<~TOML)
        [package]
        name = "x"

        [package.metadata.thermite]
        github_releases = true
      TOML
      options = { cargo_project_path: dir }
      tasks = Thermite::Tasks.new(options)

      assert_equal({ cargo_project_path: dir, github_releases: true }, tasks.options)
      assert_equal({ cargo_project_path: dir }, options)
    end

    private

    def invoke_tasks
      Rake::Task['thermite:build'].invoke
      Rake::Task['thermite:test'].invoke
      Rake::Task['thermite:clean'].invoke
    end

    def ruby_project
      dir = Dir.mktmpdir('thermite_ruby_project')
      temp_dirs << dir
      Dir.mkdir(File.join(dir, 'lib'))

      dir
    end

    def without_cargo
      original = ENV['CARGO']
      ENV['CARGO'] = File.join(Dir.tmpdir, 'thermite-missing-cargo')
      yield
    ensure
      ENV['CARGO'] = original
    end
  end
end
