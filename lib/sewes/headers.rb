# frozen_string_literal: true

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
  # Handles HTTP headers in a Hash. It suppors parsing and generating them
  # according to RFC4229. Header fields are stored in a Hash by name. A
  # field value can be an Array if multiple fields of the same name are
  # present in the header.
  class Headers
    def initialize
      @fields = {}
    end

    def []=(name, value)
      # name must only consist of visible US ASCII characters without ':'
      raise ArgumentError, "Illegal header field name #{name}" unless /\A[\x21-\x39\x41-\x7e]+\z/ =~ name

      if @fields.include?(name)
        # Some name fields can occur multiple times. These values will
        # be stored as an Array.
        unless @fields[name].is_a?(Array)
          # Convert the field value to an Array with the old value being
          # the first entry.
          first_value = @fields[name]
          @fields[name] = [first_value]
        end
        @fields[name] << value
      else
        @fields[name] = value
      end
    end

    def [](name)
      @fields[name.downcase]
    end

    # Conveniance method for self['cookie'] that always returns a Hash.
    # @return Hash
    def cookies
      get_field('cookie')
    end

    # Conveniance method for self['set-cookie']=
    def set_cookie(value)
      set_field('set-cookie', value)
    end

    # Conveniance method for self[name]= that automatically expands the field
    # value to an Array of values to store multiple values.
    # @param name [String] name of the field
    # @param value value of the field
    def set_field(name, value)
      if (field = @fields[name]).nil?
        # No field with the given name exists. Just assign the value to a new field.
        @fields[name] = value
      elsif field.respond_to?(:each)
        # A field already exists and has multiple values. Just append the new value.
        field << value
      else
        # The field exists, but only has one value. We have to convert it to an
        # Array and then append the new value.
        @fields[name] = [@fields[name]] + [value]
      end
    end

    # Convienience method for self[name] that always returns a Hash.
    # @param name [String] name of the header field
    # @return Hash
    def get_field(name)
      # We have no field with the given name.
      return {} unless (field = @fields[name])

      if field.respond_to?(:each)
        hash = {}
        fielid.each do |c|
          hash[c.name] = c
        end
        hash
      else
        { field.name => field }
      end
    end

    # Parse the provided lines for header fields. An empty line, only
    # containing CR+LF stops the parsing.
    # @return [Integer] the number of lines parsed
    def parse(lines)
      read_lines = 0
      lines.each do |line|
        read_lines += 1
        # An empty line concludes the header section
        return read_lines if line == "\r\n"

        _, name, value = line.split(/\A([\x21-\x39\x41-\x7e]+):\s([ -~]*)\s*\z/)
        # Silently ignore all invalid lines
        next if name.nil? || value.nil? || name.empty? || value.empty?
        # To avoid ambiguities, we convert all header names to lower case.
        name.downcase!

        # Some fields get special treatment. The others are unescaped
        # to deal with any encoded special characters.
        self[name] =
          case name
          when 'content-length'
            value.to_i
          when 'cookie-set', 'cookie'
            Cookie.parse(value)
          else
            CGI.unescape(value)
          end
      end

      read_lines
    end

    # Convert the header into a string that can be used as part of an HTTP exchange.
    def to_s
      s = String.new
      @fields.each do |name, value|
        if value.respond_to?(:each)
          value.each do |val|
            val = val.to_escaped_s if val.respond_to?(:to_escaped_s)
            s << "#{name}: #{val}\r\n"
          end
        else
          value = value.to_escaped_s if value.respond_to?(:to_escaped_s)
          s << "#{name}: #{value}\r\n"
        end
      end

      "#{s}\r\n"
    end
  end
end
