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
require 'thermite/builder'

module Thermite
  class BuilderTest < Minitest::Test
    include Thermite::ConfigHelper

    #
    # Stands in for {Thermite::Cargo}, writing a fake library where Cargo would put it.
    #
    class FakeCargo
      attr_reader :profiles

      def initialize(config, available:)
        @config = config
        @available = available
        @profiles = []
      end

      def available?
        @available
      end

      def build(profile)
        @profiles << profile
        library = @config.cargo_target_path(profile, @config.cargo_shared_library)
        FileUtils.mkdir_p(File.dirname(library))
        File.write(library, "built with #{profile}")
      end
    end

    #
    # Stands in for {Thermite::CustomBinary} and {Thermite::GithubReleaseBinary}.
    #
    class FakeBinarySource
      attr_reader :calls

      def initialize(result)
        @result = result
        @calls = 0
      end

      def download
        @calls += 1
        @result
      end
    end

    def test_build_with_cargo
      config = build_config(options: { ruby_project_path: ruby_project },
                            env: { 'CARGO_PROFILE' => 'debug' })
      cargo = FakeCargo.new(config, available: true)
      source = FakeBinarySource.new(true)

      builder(config, cargo, [source]).build

      assert_equal %w[debug], cargo.profiles
      assert_equal 'built with debug', File.read(config.ruby_extension_path)
      assert_equal 0, source.calls
    end

    def test_download_when_cargo_is_unavailable
      sources = [FakeBinarySource.new(true), FakeBinarySource.new(true)]

      builder(build_config, FakeCargo.new(nil, available: false), sources).build

      assert_equal [1, 0], sources.map(&:calls)
      assert_empty err.string
    end

    def test_optional_extension_when_nothing_is_available
      config = build_config(options: { optional_rust_extension: true })
      sources = [FakeBinarySource.new(false), FakeBinarySource.new(false)]

      builder(config, FakeCargo.new(nil, available: false), sources).build

      assert_equal [1, 1], sources.map(&:calls)
      assert_equal Thermite::Cargo::RECOMMENDED_MESSAGE, err.string
    end

    def test_required_extension_when_nothing_is_available
      error = assert_raises(RuntimeError) do
        builder(build_config, FakeCargo.new(nil, available: false), []).build
      end

      assert_equal Thermite::Cargo::REQUIRED_MESSAGE, error.message
      assert_empty err.string
    end

    private

    def builder(config, cargo, sources)
      Thermite::Builder.new(config, cargo: cargo, binary_sources: sources, err: err)
    end

    def err
      @err ||= StringIO.new
    end

    def ruby_project
      dir = Dir.mktmpdir('thermite_ruby_project')
      temp_dirs << dir
      Dir.mkdir(File.join(dir, 'lib'))

      dir
    end
  end
end
