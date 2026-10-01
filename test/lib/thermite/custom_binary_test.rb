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
require 'thermite/custom_binary'

module Thermite
  class CustomBinaryTest < Minitest::Test
    include Thermite::ConfigHelper

    def test_no_downloading_when_binary_uri_is_falsey
      downloader = FakeDownloader.new

      refute custom_binary(build_config(options: { binary_uri_format: false }), downloader).download
      assert_empty downloader.installed
    end

    def test_download_binary_from_custom_uri
      uri_format = 'http://example.com/download/%<version>s/%<filename>s'
      config = build_config(options: { binary_uri_format: uri_format })
      uri = "http://example.com/download/4.5.6/#{config.tarball_filename('4.5.6')}"
      downloader = FakeDownloader.new([uri])

      assert custom_binary(config, downloader).download
      assert_equal [[uri, 'Downloading compiled version (4.5.6)']], downloader.installed
    end

    def test_download_binary_from_custom_uri_not_found
      config = build_config(options: { binary_uri_format: 'http://example.com/%<filename>s' })

      refute custom_binary(config, FakeDownloader.new).download
    end

    private

    def custom_binary(config, downloader)
      Thermite::CustomBinary.new(config, downloader: downloader)
    end
  end
end
