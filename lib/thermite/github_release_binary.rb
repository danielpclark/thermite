# frozen_string_literal: true
#
# Copyright (c) 2016, 2017 Mark Lee and contributors
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

require 'rexml/document'

module Thermite
  #
  # Downloads a pre-built Rust shared library from GitHub releases.
  #
  class GithubReleaseBinary
    #
    # @param config [Thermite::Config]
    # @param downloader [#install] downloads and installs a tarball (see {Thermite::Downloader}).
    # @param http [#get] fetches the releases feed (see {Thermite::HTTPClient}).
    #
    def initialize(config, downloader:, http:)
      @config = config
      @downloader = downloader
      @http = http
    end

    #
    # Downloads a Rust binary from GitHub releases, given the target OS and architecture.
    #
    # Requires the `github_releases` option to be `true`. It uses the `repository` value in the
    # project's `Cargo.toml` (in the `package` section) to determine where the releases
    # are located.
    #
    # If the `github_release_type` is `'latest'`, it will attempt to use the appropriate binary for
    # the latest version in GitHub releases. Otherwise, it will download the appropriate binary for
    # the crate version given in `Cargo.toml`.
    #
    # @return [Boolean] whether a binary was found and installed.
    #
    def download
      return false unless @config.github_releases?

      if @config.github_release_type == 'latest'
        download_latest_release
      else
        download_cargo_version
      end
    end

    private

    def download_cargo_version
      version = @config.crate_version
      tag = format(@config.git_tag_format, version)
      install(tag, version)
    end

    def download_latest_release
      releases.any? { |tag, version| install(tag, version) }
    end

    def install(tag, version)
      filename = @config.tarball_filename(version)
      uri = "#{@config.repository_uri}/releases/download/#{tag}/#{filename}"
      @downloader.install(uri, "Downloading compiled version (#{version}) from GitHub")
    end

    #
    # The `[tag, version]` pairs of the releases whose tags match the `git_tag_regex` option,
    # newest first.
    #
    def releases
      feed = REXML::Document.new(@http.get("#{@config.repository_uri}/releases.atom"))
      tags = REXML::XPath.match(feed, '//entry/title/text()').map(&:to_s)
      tags.each_with_object([]) do |tag, list|
        match = @config.git_tag_regex.match(tag)
        list << [tag, match[1]] if match
      end
    end
  end
end
