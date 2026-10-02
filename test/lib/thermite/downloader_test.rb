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

require 'fakes'
require 'test_helper'
require 'thermite/downloader'

module Thermite
  class DownloaderTest < Minitest::Test
    URI = 'https://example.com/downloads/library-1.0.0.tar.gz'

    #
    # Stands in for {Thermite::Package}.
    #
    class FakePackage
      attr_reader :installed

      def initialize
        @installed = []
      end

      def install(tgz)
        @installed << tgz.read
      end
    end

    def test_install
      downloader = build_downloader(URI => 'tarball')

      assert downloader.install(URI, 'Downloading')
      assert_equal %w[tarball], package.installed
      assert_equal "Downloading\n", out.string
      assert_equal ['Unpacking binary: library-1.0.0.tar.gz'], logger.messages
    end

    def test_install_not_found
      refute build_downloader.install(URI, 'Downloading')
      assert_empty package.installed
    end

    private

    def build_downloader(responses = {})
      Thermite::Downloader.new(http: FakeHTTP.new(responses), package: package, logger: logger,
                               out: out)
    end

    def package
      @package ||= FakePackage.new
    end

    def logger
      @logger ||= FakeLogger.new
    end

    def out
      @out ||= StringIO.new
    end
  end
end
