# = SEWeS - A Simple Embedded WEb Server
#
# Copyright (c) 2021, 2022 by Chris Schlaeger <chris@linux.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.

module SEWeS
  # This class captures some usage statistics of the web server.
  class Statistics
    attr_reader :requests, :errors

    def initialize
      @requests = Hash.new { |k, v| k[v] = 0 }
      @errors = Hash.new { |k, v| k[v] = 0 }
    end
  end
end
