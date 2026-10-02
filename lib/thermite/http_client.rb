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

require 'net/http'
require 'stringio'
require 'uri'

module Thermite
  #
  # A minimal HTTP client that follows redirects.
  #
  class HTTPClient
    #
    # Raised when a request is redirected too many times.
    #
    class RedirectError < StandardError; end

    #
    # The exception raised for server errors. `Net::HTTPClientException` was introduced in
    # Ruby 2.6 as the new name of `Net::HTTPServerException`.
    #
    SERVER_ERROR = if Net.const_defined?(:HTTPClientException)
      Net::HTTPClientException
    else
      Net::HTTPServerException
    end

    #
    # The maximum number of redirects that are followed for one request.
    #
    MAX_REDIRECTS = 10

    #
    # @param transport [#get_response] performs a single HTTP GET request, given a `URI`.
    #                                  Defaults to `Net::HTTP`.
    #
    def initialize(transport: Net::HTTP)
      @transport = transport
    end

    #
    # Performs an HTTP GET request for `uri`, following redirects.
    #
    # @return [StringIO, nil] the response body, or `nil` if the response was a client error.
    # @raise [RedirectError] if there are too many redirects.
    # @raise [SERVER_ERROR] if the response was a server error.
    #
    def get(uri, redirects_left = MAX_REDIRECTS)
      raise RedirectError, 'Too many redirects' if redirects_left.zero?

      case (response = @transport.get_response(URI(uri)))
      when Net::HTTPClientError
        nil
      when Net::HTTPServerError
        raise SERVER_ERROR.new(response.message, response)
      when Net::HTTPRedirection
        get(URI.join(uri.to_s, response['location']).to_s, redirects_left - 1)
      else
        StringIO.new(response.body)
      end
    end
  end
end
