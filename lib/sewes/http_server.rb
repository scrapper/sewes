#!/usr/bin/env ruby -w
# encoding: UTF-8

# = SEWeS - A Simple Embedded WEb Server
#
# Copyright (c) 2021, 2022 by Chris Schlaeger <chris@linux.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.

require 'socket'
require 'cgi'
require 'base64'
require 'uri'

require_relative 'request'
require_relative 'response'
require_relative 'route'
require_relative 'statistics'

module SEWeS
  # Simple embedded application web server
  class HTTPServer
    # Supported HTTP request types.
    REQUEST_TYPES = %w[GET POST].freeze

    MAX_CONTENT_LENGTH = 2**16

    MESSAGE_CODES = {
      200 => 'OK',
      400 => 'Bad Request',
      403 => 'Forbidden',
      404 => 'Not Found',
      405 => 'Method Not Allowed',
      406 => 'Not Acceptable',
      408 => 'Request Timeout',
      413 => 'Request Entity Too Large',
      500 => 'Internal Server Error'
    }.freeze

    attr_reader :port, :statistics

    def initialize(hostname = 'localhost', port = 0, log = $stderr)
      @hostname = hostname
      @port = port
      @log = log
      @terminate = false
      @terminate_mutex = Mutex.new
      @thread = nil

      @routes = {}
      @routes_lock = Monitor.new
      @statistics = Statistics.new
    end

    # Register a given method of a given object to be called whenever a
    # request of the given type is received with the given URL path.
    def add_route(type, path, object, method)
      unless REQUEST_TYPES.include?(type)
        raise ArgumentError, 'type must be either one of ' \
          "#{REQUEST_TYPES.join(' ')}"
      end
      unless path.respond_to?(:each)
        raise ArgumentError, 'path must be an Enumerable'
      end

      path.each do |p|
        if p.include?('/')
          raise ArgumentError, 'path elements must not include a /'
        end
      end

      @routes_lock.synchronize do
        @routes["#{type}:#{path.join('/')}"] =
          Route.new(type, path, object, method)
      end
    end

    def run
      @thread = Thread.new do
        server = TCPServer.new(@hostname, @port)
        # If requested port is 0, we have to determine the actual port.
        @port = server.addr[1] if @port == 0

        while !@terminate_mutex.synchronize { @terminate } do
          begin
            @session = server.accept
            request = read_request
            if request.is_a?(Response)
              # The request was faulty. Return an error to the client.
              request.send
            else
              process_request(request).send
            end

            @session.close
            @session = nil
          rescue IOError => e
            @log.puts "HTTPServer #{e.class}: #{e.message}"
          end
        end
      end
    end

    def stop
      @terminate_mutex.synchronize { @terminate = true }
      # Send a dummy request to force the TCPServer.accept to return.
      begin
        sock = TCPSocket.new(@hostname, @port)
        sock.puts "\r\n\r\n"
        sock.close
      rescue => e
        @log.puts "HTTPServer::close error: #{e.message}"
      end
      @thread.join
      @thread = nil
    end

    # Creates a HTTP Response object to be send to client
    def response(body, code: 200, content_type: 'text/plain')
      Response.new(@session, @log, code, body, content_type)
    end

    # Creates a HTTP error Response object to be send to client
    def error(code, message)
      @statistics.errors[code] += 1
      @log.puts message
      Response.new(@session, @log, code, message)
    end

    private

    def read_request
      # Read the first part of the request. It may be the only part.
      request = read_with_timeout(2048, 0.02)

      # It must not be empty.
      if request.empty? || (lines = request.lines).length < 3
        return error(400, 'Request is empty')
      end

      method, path, version = request.lines[0].split
      # Ensure that the request type is supported.
      unless method && REQUEST_TYPES.include?(method)
        return error(405, "Only the following request methods are " +
                     "allowed: #{REQUEST_TYPES.join(' ')}")
      end

      headers = {}
      body = ''
      mode = :headers

      lines[1..].each do |line|
        if mode == :headers
          if line == "\r\n"
            # An empty line switches to body parsing mode.
            mode = :body
          else
            header, value = line.split
            next if header.nil? || value.nil? || header.empty? || value.empty?

            header = header.gsub(':', '').downcase

            # Store the valid header
            if headers.include?(header)
              # Some header fields can occur multiple times. These values will
              # be stored as an Array.
              unless headers[header].is_a?(Array)
                first_value = headers[header]
                headers[header] = [first_value]
              end
              headers[header] << value
            else
              headers[header] = value
            end
          end
        else
          # Append the read line to the body.
          body += line
        end
      end

      content_length = 0
      if headers['content-length']
        content_length = headers['content-length'].to_i
        # We only support 65k long requests to prevent DOS attacks.
        if content_length > MAX_CONTENT_LENGTH
          return error(413, 'Content length must be smaller than ' \
                       "#{MAX_CONTENT_LENGTH}")
        end

        body += read_with_timeout(content_length - body.bytesize, 5)
      end
      body.chomp!

      # The request is only valid if the body length matches the content
      # length specified in the header.
      if body.bytesize != content_length
        return error(408, 'Request timeout. Body length ' \
                     "(#{body.bytesize}) does not " \
                     "match specified content length (#{content_length})")
      end

      @statistics.requests[method] += 1

      # Return the full request.
      Request.new(path, method, version, headers, body)
    end

    def read_with_timeout(maxbytes, timeout_secs)
      str = ''

      deadline = Time.now - timeout_secs
      fds = [@session]
      while maxbytes.positive? && timeout_secs > 0.0
        break unless IO.select(fds, [], [], timeout_secs)

        # We only have one socket that we are listening on. If select()
        # fires with a true result, we have something to read from @session.
        begin
          s = @session.readpartial(maxbytes)
        rescue EOFError
          break
        end
        maxbytes -= s.bytesize
        str += s
        timeout_secs = deadline - Time.now
      end

      str
    end

    def process_request(request)
      # Construct a dummy URI so we can use the URI class to parse the request
      # and extract the path and parameters.
      uri = URI("http://#{request.headers['host'] || 'localhost'}" +
                request.path)

      parameter = (query = uri.query) ? CGI.parse(query) : {}

      path = uri.path.split('/')
      path.shift

      @routes_lock.synchronize do
        unless (route = @routes["#{request.method}:#{path.join('/')}"])
          return error(404, "Path not found: #{uri.path}")
        end

        return route.object.send(route.method, parameter, request)
      end
    end
  end
end
