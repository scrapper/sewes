# = SEWeS - A Simple Embedded WEb Server
#
# Copyright (c) 2021, 2022 by Chris Schlaeger <chris@linux.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.

module SEWeS
  # This class models a HTTP request.
  class Request
    attr_reader :code, :path, :method, :version, :headers, :body

    def initialize(path, method, version, headers, body)
      @path = path
      @method = method
      @version = version
      @headers = headers
      @body = body
    end

    def cookies
      pp @headers
      return {} unless (cookies = @headers['Cookie'] || @headers['cookie'])

      # Make sure cookies is always an Array even if only one header line was
      # provided.
      cookies = [cookies] unless cookies.is_a?(Array)

      cookie_hash = {}
      cookies.each do |cookie|
        (c = Cookie.parse(cookie)) && cookie_hash[c.name] = c
      end

      puts "Cookie Hash:"
      pp cookie_hash
      cookie_hash
    end
  end
end
