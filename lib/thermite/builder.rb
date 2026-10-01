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

require 'fileutils'
require 'thermite/cargo'

module Thermite
  #
  # Builds the Rust shared library with Cargo, or downloads a pre-built one when Cargo is not
  # available.
  #
  class Builder
    #
    # @param config [Thermite::Config]
    # @param cargo [Thermite::Cargo]
    # @param binary_sources [Array<#download>] tried in order when Cargo is not available, until
    #                                          one of them returns `true` (see
    #                                          {Thermite::CustomBinary} and
    #                                          {Thermite::GithubReleaseBinary}).
    # @param err [#write] receives the warning printed when the extension is optional and cannot
    #                     be built or downloaded. Defaults to `$stderr`.
    #
    def initialize(config, cargo:, binary_sources:, err: $stderr)
      @config = config
      @cargo = cargo
      @binary_sources = binary_sources
      @err = err
    end

    #
    # Builds or downloads the Rust shared library into {Thermite::Config#ruby_extension_path}.
    #
    # @raise [RuntimeError] if Cargo is unavailable, no pre-built library could be downloaded and
    #                       the `optional_rust_extension` option is not set.
    #
    def build
      if @cargo.available?
        build_with_cargo
      elsif @binary_sources.none?(&:download)
        report_missing_cargo
      end
    end

    private

    def build_with_cargo
      profile = @config.cargo_profile
      @cargo.build(profile)
      FileUtils.cp(@config.cargo_target_path(profile, @config.cargo_shared_library),
                   @config.ruby_extension_path)
    end

    def report_missing_cargo
      raise Cargo::REQUIRED_MESSAGE unless @config.optional_rust_extension?

      @err.write(Cargo::RECOMMENDED_MESSAGE)
    end
  end
end
