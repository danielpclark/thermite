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

module Thermite
  #
  # On macOS, rewrites the libruby path recorded in the Rust shared library, so that a library
  # built on one machine can be installed on another. On other platforms, does nothing.
  #
  class InstallNameTool
    #
    # Placeholder for the libruby path while the library is packaged.
    #
    LIBRUBY_PLACEHOLDER = '@libruby_path@'

    #
    # @param config [Thermite::Config]
    # @param runner [#system] runs the `install_name_tool` command. Defaults to `Kernel`.
    #
    def initialize(config, runner: Kernel)
      @config = config
      @runner = runner
    end

    #
    # Replaces the local libruby path with a placeholder in `library_path`, a copy of the library
    # that is about to be packaged.
    #
    def before_packaging(library_path)
      return unless @config.darwin?

      install_name_tool('-change', @config.libruby_path, LIBRUBY_PLACEHOLDER, library_path)
    end

    #
    # Replaces the placeholder with the local libruby path in the installed library
    # ({Thermite::Config#ruby_extension_path}), after a packaged library is unpacked.
    #
    def after_unpacking
      return unless @config.darwin?

      library_path = @config.ruby_extension_path
      install_name_tool('-id', library_path, library_path)
      install_name_tool('-change', LIBRUBY_PLACEHOLDER, @config.libruby_path, library_path)
    end

    private

    def install_name_tool(*args)
      @runner.system('install_name_tool', *args)
    end
  end
end
