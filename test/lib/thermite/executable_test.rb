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
require 'thermite/executable'

module Thermite
  class ExecutableTest < Minitest::Test
    def setup
      @dir = Dir.mktmpdir('thermite_executable')
    end

    def teardown
      FileUtils.rm_rf(@dir)
    end

    def test_find_in_path
      executable = create_file('tool', 0o755)

      assert_equal executable, Thermite::Executable.find('tool', path: search_path)
    end

    def test_find_absolute_path
      executable = create_file('tool', 0o755)

      assert_equal executable, Thermite::Executable.find(executable, path: '')
    end

    def test_ignores_files_that_are_not_executable
      skip 'File modes are not enforced on Windows' if Gem.win_platform?
      create_file('tool', 0o644)

      assert_nil Thermite::Executable.find('tool', path: search_path)
    end

    def test_missing_executable
      assert_nil Thermite::Executable.find('tool', path: search_path)
    end

    private

    def search_path
      [File.join(@dir, 'missing'), @dir].join(File::PATH_SEPARATOR)
    end

    def create_file(name, mode)
      filename = File.join(@dir, name)
      File.write(filename, '')
      File.chmod(mode, filename)

      filename
    end
  end
end
