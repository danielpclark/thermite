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
  # Downloads a pre-built Rust shared library from a custom URI.
  #
  class CustomBinary
    #
    # @param config [Thermite::Config]
    # @param downloader [#install] downloads and installs a tarball (see {Thermite::Downloader}).
    #
    def initialize(config, downloader:)
      @config = config
      @downloader = downloader
    end

    #
    # Downloads a Rust binary using a custom URI format, given the target OS and architecture.
    #
    # Requires the `binary_uri_format` option to be set. The version of the binary is the `version`
    # option (by default, the crate version given in `Cargo.toml`).
    #
    # @return [Boolean] whether a binary was found and installed.
    #
    def download
      return false unless @config.binary_uri_format

      version = @config.version
      uri = format(@config.binary_uri_format,
                   filename: @config.tarball_filename(version),
                   version: version)

      @downloader.install(uri, "Downloading compiled version (#{version})")
    end
  end
end
