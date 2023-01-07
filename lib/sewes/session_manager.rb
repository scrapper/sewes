# frozen_string_literal: true

# = SEWeS - A Simple Embedded WEb Server
#
# Copyright (c) 2021, 2022 by Chris Schlaeger <chris@linux.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.

require_relative 'session'

module SEWeS
  # Manages the sessions of authenticated users.
  class SessionManager
    # The minimum time between pruning the session lists of expired sessions.
    PRUNE_INTERVAL_SECONDS = 60 * 5

    def initialize(session_lifetime_seconds = 60 * 60 * 24)
      @session_lifetime_seconds = session_lifetime_seconds
      @sessions_by_key = {}
      @sessions_by_user = {}
      @timestamp_last_cleanup = Time.now
    end

    # Create a new Session for the given user. If there is already a session
    # for this user, the old session is replaced.
    # @param user [String] login or user ID
    # @return [Session] New session for the user
    def new_session(user)
      if (session = @sessions_by_user[user])
        # If we already have an existing session for the user, delete the old one.
        # We only allow 1 session per user to prevent a DOS by generating too many
        # sessions.
        key = session.key
        @sessions_by_user.delete(user)
        @sessions_by_key.delete(key)
      end

      session = Session.new(user, @session_lifetime_seconds)
      @sessions_by_key[session.key] =
        @sessions_by_user[user] = session
    end

    # Get the Session for the key
    # @param key [String]
    # @return [Session] The session that matches the given key. Returns nil
    #         if no valid Session is found.
    def session(key)
      prune
      return nil unless (session = @sessions_by_key[key]) && session.valid?

      session
    end

    def valid_session?(key)
      prune

      (session = @sessions_by_key[key]) && session.valid?
    end

    # Renew the session key
    # @param session [Session] Session to renew the key for
    def renew(session)
      @sessions_by_key.delete(session.key)
      session.renew
      @sessions_by_key[session.key] = session
    end

    private

    def prune
      return if Time.now < @timestamp_last_cleanup + PRUNE_INTERVAL_SECONDS

      @sessions_by_key.delete_if { |_, s| !s.valid? }
      @sessions_by_user.delete_if { |_, s| !s.valid? }
      @timestamp_last_cleanup = Time.now
    end
  end
end
