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

module Thermite
  #
  # Locates executables in the `PATH`, without requiring `mkmf` (which adds its helper methods to
  # every object).
  #
  module Executable
    #
    # Finds the executable named `name`.
    #
    # @param name [String] an executable name, or an absolute path to an executable.
    # @param path [String, nil] directories to search, joined by `File::PATH_SEPARATOR`.
    #                           Defaults to the `PATH` environment variable.
    # @return [String, nil] the path to the executable, or `nil` if it cannot be found.
    #
    def self.find(name, path: ENV['PATH'])
      if File.expand_path(name) == name
        executable_candidate(name)
      else
        search_dirs(path).each do |dir|
          found = executable_candidate(File.join(dir, name))
          return found if found
        end
        nil
      end
    end

    #
    # Returns `filename` (or `filename` with one of the platform's executable extensions) if it is
    # an executable file.
    #
    def self.executable_candidate(filename)
      ['', *executable_extensions].map { |ext| "#{filename}#{ext}" }.find do |candidate|
        File.file?(candidate) && File.executable?(candidate)
      end
    end
    private_class_method :executable_candidate

    def self.search_dirs(path)
      return %w[/usr/local/bin /usr/bin /bin] unless path

      path.split(File::PATH_SEPARATOR).map { |dir| dir.sub(/\A"(.*)"\z/m, '\1') }
    end
    private_class_method :search_dirs

    def self.executable_extensions
      exts = RbConfig::CONFIG['EXECUTABLE_EXTS'].to_s.split
      exts = [RbConfig::CONFIG['EXEEXT']] if exts.empty?
      exts.reject { |ext| ext.nil? || ext.empty? }
    end
    private_class_method :executable_extensions
  end
end
