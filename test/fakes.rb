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
  # Stands in for {Thermite::Downloader}, recording the URIs it is asked to install.
  #
  class FakeDownloader
    attr_reader :installed

    #
    # `available_uris` are the URIs that "exist"; installing any other URI returns `false`.
    #
    def initialize(available_uris = [])
      @available_uris = available_uris
      @installed = []
    end

    def install(uri, announcement)
      @installed << [uri, announcement]
      @available_uris.include?(uri)
    end
  end

  #
  # Stands in for {Thermite::HTTPClient}, serving fixed responses.
  #
  class FakeHTTP
    attr_reader :requested

    def initialize(responses = {})
      @responses = responses
      @requested = []
    end

    def get(uri)
      @requested << uri
      body = @responses[uri]
      body && StringIO.new(body)
    end
  end
end
