# frozen_string_literal: true

# = SEWeS - A Simple Embedded WEb Server
#
# Copyright (c) 2021, 2022 by Chris Schlaeger <chris@linux.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.

module SEWeS
  # Simple class to map a HTTP request type and path to a Proc object.
  Route = Struct.new(:type, :path, :proc)
end
