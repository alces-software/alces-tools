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
require 'digest/sha1'
require 'securerandom'

module Alces
  module Tools
    module Hashing
      def valid_hash?(hash, secret, opts = {})
        return false if hash.nil?
        salt_len = (opts[:salt_length] || 8).to_i
        raise "Invalid salt length, must be positive integer" if salt_len <= 0
        pepper = opts[:pepper]
        salt = hash[0..salt_len-1]
        hash == construct_hash(salt, pepper, secret)
      rescue
        STDERR.puts "#{$!.class}: #{$!.message}"
        STDERR.puts $!.backtrace.join("\n")
        false
      end
      
      def create_hash(secret, opts = {})
        salt = opts[:salt] || SecureRandom.base64(6) # generates an 8-character salt
        salt_len = (opts[:salt_length] || salt.length).to_i
        # XXX What happens if opts[:salt_length] is greater than salt.length.
        # The hash will be constructed without problem. Checking if it is a
        # valid hash is likely to fail though. The user will use the same
        # salt_length in both places and extract salt plus more.
        raise "Invalid salt length, must be positive integer" if salt_len <= 0
        salt = salt[0..salt_len-1]
        pepper = opts[:pepper]
        construct_hash(salt, pepper, secret)
      end

      private

      def construct_hash(salt, pepper, secret)
        result = [Digest::SHA1.digest("#{salt}:#{secret}:#{pepper}")].pack('m').chomp
        "#{salt}#{result}"
      end

      extend self
    end
  end
end
