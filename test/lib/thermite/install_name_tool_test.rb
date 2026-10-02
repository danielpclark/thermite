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
require 'thermite/install_name_tool'

module Thermite
  class InstallNameToolTest < Minitest::Test
    include Thermite::ConfigHelper

    #
    # Records the commands it is asked to run.
    #
    class FakeRunner
      attr_reader :commands

      def initialize
        @commands = []
      end

      def system(*command)
        @commands << command
        true
      end
    end

    def test_does_nothing_on_linux
      tool = install_name_tool(build_config(options: { ruby_project_path: '/project' }))
      tool.before_packaging('/tmp/staged/lib/test_crate.so')
      tool.after_unpacking

      assert_empty runner.commands
    end

    def test_before_packaging_on_darwin
      install_name_tool(darwin_config).before_packaging('/tmp/staged/lib/test_crate.so')

      assert_equal [['install_name_tool', '-change', '/opt/ruby/lib/libruby.2.7.dylib',
                     '@libruby_path@', '/tmp/staged/lib/test_crate.so']],
                   runner.commands
    end

    def test_after_unpacking_on_darwin
      install_name_tool(darwin_config).after_unpacking

      assert_equal [['install_name_tool', '-id', '/project/lib/test_crate.so',
                     '/project/lib/test_crate.so'],
                    ['install_name_tool', '-change', '@libruby_path@',
                     '/opt/ruby/lib/libruby.2.7.dylib', '/project/lib/test_crate.so']],
                   runner.commands
    end

    private

    def darwin_config
      build_config(options: { ruby_project_path: '/project' },
                   rbconfig: { 'target_os' => 'darwin19', 'LIBRUBY_SO' => 'libruby.2.7.dylib' })
    end

    def install_name_tool(config)
      Thermite::InstallNameTool.new(config, runner: runner)
    end

    def runner
      @runner ||= FakeRunner.new
    end
  end
end
