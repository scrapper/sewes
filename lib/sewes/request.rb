# frozen_string_literal: true

# = SEWeS - A Simple Embedded WEb Server
#
# Copyright (c) 2021, 2022 by Chris Schlaeger <chris@linux.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
require 'uri'

require_relative 'headers'

module SEWeS
  # This class models a HTTP request.
  class Request
    attr_reader :code, :peer_address, :method, :version, :headers, :body

    def initialize(peer_address, path, method, version, headers, body)
      @peer_address = peer_address
      @path = path
      @method = method
      @version = version
      @headers = headers
      @body = body
    end

    # @return [String] The path of the request (without the arguments)
    def path
      uri = URI("http://#{@headers['host'] || 'localhost'}" + @path)
      path = uri.path
      # Drop the leading '/'
      path[1..]
    end

    # @return [Hash] The paramater used for the request
    def parameter
      # Construct a dummy URI so we can use the URI class to parse the request
      # and extract the path and parameters.
      uri = URI("http://#{@headers['host'] || 'localhost'}" + @path)

      (query = uri.query) ? CGI.parse(query) : {}
    end

    # @return [Hash] The cookies provided by the request
    def cookies
      return {} unless (cookies = @headers['Cookie'] || @headers['cookie'])

      # Make sure cookies is always an Array even if only one header line was
      # provided.
      cookies = [cookies] unless cookies.is_a?(Array)

      cookie_hash = {}
      cookies.each do |cookie|
        (c = Cookie.parse(cookie)) && cookie_hash[c.name] = c
      end

      cookie_hash
    end
  end
end
