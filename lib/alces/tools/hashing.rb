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
        return false unless hash.is_a?(String)
        salt_len = (opts[:salt_length] || 8).to_i
        raise "Invalid salt length, must be positive integer" if salt_len <= 0
        pepper = opts[:pepper]
        salt = hash[0..salt_len-1]
        constructed = construct_hash(salt, pepper, secret, urlsafe: opts[:urlsafe] || false)
        constructed = constructed[0..(opts[:length]-1)] if opts[:length]
        hash == constructed
      rescue
        STDERR.puts "#{$!.class}: #{$!.message}"
        STDERR.puts $!.backtrace.join("\n")
        false
      end

      def create_hash(secret, opts = {})
        salt = opts[:salt] || SecureRandom.urlsafe_base64(6) # generates an 8-character salt
        salt_len = (opts[:salt_length] || salt.length).to_i
        raise "Invalid salt length, must be positive integer" if salt_len <= 0
        if salt_len > salt.length
          # If the salt length is greater than the length of the salt, the
          # hash will be created with a smaller than expected salt. When
          # checking the validity of the hash, salt_len characters will be
          # extracted from the hash. This will be too many, resulting in all
          # hashes being invalid.
          raise "Invalid salt length. the salt length is greater than the length of the salt"
        end
        salt = salt[0..salt_len-1]
        pepper = opts[:pepper]
        h = construct_hash(salt, pepper, secret, urlsafe: opts[:urlsafe] || false)
        if opts[:length]
          if opts[:length] <= salt_len
            raise 'Invalid length; the specified length is shorter or equal to the length of the salt'
          end
          h = h[0..(opts[:length] - 1)]
        end
        h
      end

      private

      def construct_hash(salt, pepper, secret, urlsafe: false)
        if urlsafe
          require 'base64'
          result = Base64.urlsafe_encode64(Digest::SHA1.digest("#{salt}:#{secret}:#{pepper}"))
        else
          result = [Digest::SHA1.digest("#{salt}:#{secret}:#{pepper}")].pack('m').chomp
        end
        "#{salt}#{result}"
      end

      extend self
    end
  end
end
