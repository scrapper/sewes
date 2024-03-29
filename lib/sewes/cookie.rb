# frozen_string_literal: true

# = SEWeS - A Simple Embedded WEb Server
#
# Copyright (c) 2021, 2022 by Chris Schlaeger <chris@linux.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.

module SEWeS
  # Handles HTTP cookies according to RFC6265
  class Cookie
    attr_reader :name, :value, :same_site

    attr_accessor :expires, :max_age, :domain, :path, :secure,
                  :http_only

    def initialize(name, value)
      unless /\A[A-Za-z0-9_]+\z/ =~ name
        raise ArgumentError, "Cookie name #{name} may only contain US ASCII characters " \
                             '(no control or special characters)'
      end

      @name = name
      @value = value
      @expires = nil
      @max_age = nil
      @domain = nil
      @path = nil
      @secure = nil
      @http_only = nil
      @same_site = nil
    end

    def to_escaped_s
      cookie = "#{@name}=#{CGI.escape(@value)}"

      @expires && (cookie += @expires.utc.strftime('; Expires=%a, %d %b %Y %H:%M:%S GMT'))
      @max_age && (cookie += "; Max-age=#{@max_age}")
      @domain && (cookie += "; Domain=#{CGI.escape(@domain)}")
      @path && (cookie += "; Path=#{CGI.escape(@path)}")
      @same_site && (cookie += "; SameSite=#{@same_site}")
      @secure && (cookie += '; Secure')
      @http_only && (cookie += '; HttpOnly')

      cookie
    end

    def assign_optional_value(name, value, silent_errors: false)
      case name.downcase
      when 'expires'
        begin
          @expires = Time.parse(CGI.unescape(value))
        rescue ArgumentError => e
          raise e unless silent_errors
        end
      when 'max-age'
        unless /[1-9][0-9]*/ =~ value
          raise ArgumentError, "Max-age (#{value}) must be a positive number"
        end

        @max_age = value.to_i
      when 'domain'
        @domain = CGI.unescape(value)
      when 'path'
        @path = CGI.unescape(value)
      when 'samesite'
        # This is not part of RFC6265.
        check_same_site(value)

        @same_site = value
      else
        raise ArgumentError, "Unknown cookie attribute #{name}" unless silent_errors
      end
    end

    def same_site=(value)
      check_same_site(value)
      @same_site = value
    end

    def assign_flag(name, silent_errors: false)
      case name.downcase
      when 'secure'
        @secure = true
      when 'httponly'
        @http_only = true
      else
        raise ArgumentError, "Unknown cookie attribute #{name}" unless silent_errors
      end
    end

    private

    def check_same_site(value)
      return if %w[strict lax none].include?(value.downcase)

      raise ArgumentError, "samesite must be 'strict', 'lax' or 'none', not '#{value}'"
    end
  end
end
