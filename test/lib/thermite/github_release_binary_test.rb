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

require 'fakes'
require 'test_helper'
require 'thermite/github_release_binary'

module Thermite
  class GithubReleaseBinaryTest < Minitest::Test
    include Thermite::ConfigHelper

    PROJECT_URI = 'https://github.com/user/project'

    def test_no_downloading_when_github_releases_is_false
      config = build_config(options: { github_releases: false }, cargo_toml: package_toml)
      downloader = FakeDownloader.new

      refute github_release_binary(config, downloader).download
      assert_empty downloader.installed
    end

    def test_download_cargo_version_from_github_release
      config = build_config(options: { github_releases: true }, cargo_toml: package_toml)
      uri = release_uri(config, 'v4.5.6', '4.5.6')
      downloader = FakeDownloader.new([uri])

      assert github_release_binary(config, downloader).download
      assert_equal [[uri, 'Downloading compiled version (4.5.6) from GitHub']], downloader.installed
    end

    def test_download_cargo_version_from_github_release_with_custom_git_tag_format
      config = build_config(options: { github_releases: true, git_tag_format: 'VER_%s' },
                            cargo_toml: package_toml)
      uri = release_uri(config, 'VER_4.5.6', '4.5.6')

      assert github_release_binary(config, FakeDownloader.new([uri])).download
    end

    def test_download_version_option_from_github_release
      config = build_config(options: { github_releases: true, version: '7.8.9' },
                            cargo_toml: package_toml)
      uri = release_uri(config, 'v7.8.9', '7.8.9')
      downloader = FakeDownloader.new([uri])

      assert github_release_binary(config, downloader).download
      assert_equal [[uri, 'Downloading compiled version (7.8.9) from GitHub']], downloader.installed
    end

    def test_download_cargo_version_from_github_release_not_found
      config = build_config(options: { github_releases: true }, cargo_toml: package_toml)

      refute github_release_binary(config, FakeDownloader.new).download
    end

    def test_download_cargo_version_from_github_release_with_no_repository
      config = build_config(options: { github_releases: true })

      assert_raises KeyError do
        github_release_binary(config, FakeDownloader.new).download
      end
    end

    def test_download_latest_binary_from_github_release
      config = latest_config('v(.*)_rust')
      uri = release_uri(config, 'v0.1.11_rust', '0.1.11')
      downloader = FakeDownloader.new([uri])

      assert github_release_binary(config, downloader, releases_feed).download
      assert_equal [release_uri(config, 'v0.1.12_rust', '0.1.12'), uri],
                   downloader.installed.map(&:first)
    end

    def test_download_latest_binary_from_github_release_no_releases_match_regex
      downloader = FakeDownloader.new

      refute github_release_binary(latest_config, downloader, releases_feed).download
      assert_empty downloader.installed
    end

    def test_download_latest_binary_from_github_release_no_tarball_found
      downloader = FakeDownloader.new

      refute github_release_binary(latest_config('v(.*)_rust'), downloader, releases_feed).download
      assert_equal 2, downloader.installed.size
    end

    def test_download_latest_binary_from_github_release_without_feed
      refute github_release_binary(latest_config('v(.*)_rust'), FakeDownloader.new).download
    end

    private

    def github_release_binary(config, downloader, http = FakeHTTP.new)
      Thermite::GithubReleaseBinary.new(config, downloader: downloader, http: http)
    end

    def latest_config(git_tag_regex = nil)
      options = { github_releases: true, github_release_type: 'latest' }
      options[:git_tag_regex] = git_tag_regex if git_tag_regex
      build_config(options: options, cargo_toml: package_toml)
    end

    def package_toml
      "[package]\nname = \"project\"\nversion = \"4.5.6\"\nrepository = \"#{PROJECT_URI}\"\n"
    end

    def release_uri(config, tag, version)
      "#{PROJECT_URI}/releases/download/#{tag}/#{config.tarball_filename(version)}"
    end

    def releases_feed
      atom = File.read(fixtures_path('github', 'releases.atom'))
      FakeHTTP.new("#{PROJECT_URI}/releases.atom" => atom)
    end
  end
end
