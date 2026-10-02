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
  # Downloads a packaged Rust shared library and installs it into the Ruby project.
  #
  class Downloader
    #
    # @param http [#get] fetches a URI, returning an IO or `nil` (see {Thermite::HTTPClient}).
    # @param package [#install] installs a downloaded tarball (see {Thermite::Package}).
    # @param logger [#debug] receives debug messages (see {Thermite::DebugLog}).
    # @param out [#puts] receives progress messages. Defaults to `$stdout`.
    #
    def initialize(http:, package:, logger:, out: $stdout)
      @http = http
      @package = package
      @logger = logger
      @out = out
    end

    #
    # Downloads the tarball at `uri` and installs it, printing `announcement` first.
    #
    # @return [Boolean] whether a tarball was found and installed.
    #
    def install(uri, announcement)
      @out.puts announcement
      return false unless (tgz = @http.get(uri))

      @logger.debug "Unpacking binary: #{File.basename(uri)}"
      @package.install(tgz)
      true
    end
  end
end
