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
require 'thermite/debug_log'

module Thermite
  class DebugLogTest < Minitest::Test
    def test_debug_without_filename
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          Thermite::DebugLog.new(nil).debug('will not exist')
          assert_empty Dir.children(dir)
        end
      end
    end

    def test_debug_with_filename
      Dir.mktmpdir do |dir|
        filename = File.join(dir, 'debug.log')
        log = Thermite::DebugLog.new(filename)

        refute File.exist?(filename)
        log.debug('some message')
        log.debug('another message')

        assert_equal "some message\nanother message\n", File.read(filename)
      end
    end
  end
end
