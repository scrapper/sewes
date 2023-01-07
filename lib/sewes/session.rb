# frozen_string_literal: true

# = SEWeS - A Simple Embedded WEb Server
#
# Copyright (c) 2021, 2022 by Chris Schlaeger <chris@linux.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.

require 'time'
require 'securerandom'

module SEWeS
  # Stores session key and privileges
  class Session
    attr_reader :key, :user_id, :valid_until

    # Create a new Session object for the user session.
    # @param user_id [String] ID or login of the user
    # @param timeout_seconds [Integer] Number of seconds the session should be valid
    # @param privileges [Hash] A hash to track session privileges as key/value pairs
    def initialize(user_id, timeout_seconds, privileges = {})
      @user_id = user_id
      @timeout_seconds = timeout_seconds
      renew
      @privileges = privileges
    end

    # @return [Boolean] True if session is still valid, false if expired.
    def valid?
      Time.now < @valid_until
    end

    # Renew the session key and extend the timeout.
    def renew
      @key = SecureRandom.base64(64)
      @valid_until = Time.now + @timeout_seconds
    end

    def privilege?(name)
      valid? || @privileges[name]
    end
  end
end
