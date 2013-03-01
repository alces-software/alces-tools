################################################################################
# (c) Copyright 2013 Alces Software Ltd & Stephen F Norledge.                  #
#                                                                              #
# Alces HPC Software Toolkit                                                   #
#                                                                              #
# This file/package is part of Symphony                                        #
#                                                                              #
# Symphony is free software: you can redistribute it and/or modify it under    #
# the terms of the GNU Affero General Public License as published by the Free  #
# Software Foundation, either version 3 of the License, or (at your option)    #
# any later version.                                                           #
#                                                                              #
# Symphony is distributed in the hope that it will be useful, but WITHOUT      #
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or        #
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License #
# for more details.                                                            #
#                                                                              #
# You should have received a copy of the GNU Affero General Public License     #
# along with Symphony.  If not, see <http://www.gnu.org/licenses/>.            #
#                                                                              #
# For more information on the Symphony Toolkit, please visit:                  #
# http://www.alces-software.org/symphony                                       #
#                                                                              #
################################################################################

# Buffers received messages keeping a tally of the number of times that each
# message has been received.
#
#     tb = ThrottlingBuffer.new
#     message = "My message"
#     tb << [message, "#{Time.now} message"]
#     sleep 1
#     tb << [message, "#{Time.now} message"]
#     sleep 1
#     tb << [message, "#{Time.now} message"]
#     tb.each do |m|
#       puts m
#     end
#     # => "2013-02-28 16:24:17 +0000 My message: message received 3 times"
#
# The first argument given to << is the key used to identify messages. It must
# be the same for each message that should be throttled. The full message of
# the first message received is used in the rendered output. In the example
# above, the displayed time is from the first message buffered.
#
# WARNING: This class is not thread safe.
#
class ThrottlingBuffer

  def initialize
    @buffer = Hash.new { |h,k| k[k] = [] }
  end

  def <<(args)
    buffer_message(args[0], args[1])
  end

  def size
    @buffer.size
  end

  def each
    @buffer.each do |_, val|
      count = val[0]
      message = val[1]
      if count > 1
        nl = message[-1] == ?\n
        message = message[0...-1] if nl
        message = "#{message}: message received #{count} times"
        message << ?\n if nl
      end
      yield message
    end
  end

  def buffer_message(message, formatted_message)
    if @buffer.key?(message)
      m = @buffer[message]
      m[0] += 1
    else
      @buffer[message] = [1, formatted_message]
    end
  end
end
