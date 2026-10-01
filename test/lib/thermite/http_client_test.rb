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

require 'test_helper'
require 'thermite/http_client'

module Thermite
  class HTTPClientTest < Minitest::Test
    #
    # Serves canned responses, keyed by URI.
    #
    class FakeTransport
      attr_reader :requested

      def initialize(responses)
        @responses = responses
        @requested = []
      end

      def get_response(uri)
        @requested << uri.to_s
        @responses.fetch(uri.to_s)
      end
    end

    #
    # A successful response with a fixed body.
    #
    class OK < Net::HTTPOK
      def initialize(body)
        super('1.1', '200', 'OK')
        @fixed_body = body
      end

      def body
        @fixed_body
      end
    end

    def test_get
      assert_equal 'body', client('http://example.com/a' => OK.new('body')).get('http://example.com/a').read
    end

    def test_get_client_error
      response = Net::HTTPNotFound.new('1.1', '404', 'Not Found')
      assert_nil client('http://example.com/a' => response).get('http://example.com/a')
    end

    def test_get_server_error
      response = Net::HTTPInternalServerError.new('1.1', '500', 'Internal Server Error')
      assert_raises(Thermite::HTTPClient::SERVER_ERROR) do
        client('http://example.com/a' => response).get('http://example.com/a')
      end
    end

    def test_get_follows_redirects
      transport = FakeTransport.new(
        'http://example.com/a' => redirect(Net::HTTPFound, 'https://cdn.example.com/b'),
        'https://cdn.example.com/b' => redirect(Net::HTTPMovedPermanently, '/c'),
        'https://cdn.example.com/c' => OK.new('body')
      )

      assert_equal 'body', Thermite::HTTPClient.new(transport: transport).get('http://example.com/a').read
      assert_equal %w[http://example.com/a https://cdn.example.com/b https://cdn.example.com/c],
                   transport.requested
    end

    def test_get_too_many_redirects
      response = redirect(Net::HTTPFound, 'http://example.com/a')

      assert_raises(Thermite::HTTPClient::RedirectError) do
        client('http://example.com/a' => response).get('http://example.com/a')
      end
    end

    private

    def client(responses)
      Thermite::HTTPClient.new(transport: FakeTransport.new(responses))
    end

    def redirect(klass, location)
      response = klass.new('1.1', '302', 'Redirect')
      response['location'] = location
      response
    end
  end
end
