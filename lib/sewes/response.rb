# = SEWeS - A Simple Embedded WEb Server
#
# Copyright (c) 2021, 2022 by Chris Schlaeger <chris@linux.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.

require 'cgi'

require_relative 'cookie'

module SEWeS
  # HTTP response to the client
  class Response
    attr_reader :code, :body, :content_type

    def initialize(session, log, code, body = '', content_type = 'text/plain')
      @session = session
      @log = log
      @code = code
      @body = body
      @content_type = content_type
      @cookies = {}
    end

    def set_cookie(cookie)
      @cookies[cookie.name] = cookie
    end

    def send
      message = HTTPServer::MESSAGE_CODES[@code] || 'Internal Server Error'

      http = "HTTP/1.1 #{@code} #{message}\r\n" \
        "Content-Type: #{@content_type}\r\n"
      @body.empty? || (http += "Content-Length: #{@body.bytesize}\r\n")

      @cookies.each do |_, cookie|
        http += "Set-Cookie: #{cookie}\r\n"
      end
      http += "Connection: close\r\n"

      @body.empty? || (http += "\r\n#{@body}")

      begin
        @session.print(http)
      rescue => e
        @log.puts "SEWeS::Response.send failed: #{e.message}"
      end

      self
    end

    private

    def format_cookie_fragment(name, value)
      if value.is_a?(TrueClass)
        "#{name};"
      else
        "#{name}=#{value};"
      end
    end
  end
end
