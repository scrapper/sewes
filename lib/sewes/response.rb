# = SEWeS - A Simple Embedded WEb Server
#
# Copyright (c) 2021, 2022 by Chris Schlaeger <chris@linux.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.

module SEWeS
  # This class models a HTTP response
  class Response
    attr_reader :code, :body, :content_type

    def initialize(code, body = '', content_type = 'text/plain')
      @code = code
      @body = body
      @content_type = content_type
    end
  end
end
