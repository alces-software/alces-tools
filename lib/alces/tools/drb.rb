################################################################################
# (c) Copyright 2007-2011 Alces Software Ltd & Stephen F Norledge.             #
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
require 'drb'
require 'alces/tools/ssl_configurator'

module Alces
  module Tools
    class DRb < Struct.new(:intfs, :port, :ssl, :front)
      include Alces::Tools::SSLConfigurator

      class << self
        def listen(config, front)
          new(config, front).listen
        end
      end

      def initialize(config, front)
        super(config.interfaces,
              config.port,
              (config.ssl rescue nil),
              front)
      end

      def listen
        bind_addresses.each do |a|
          ::DRb.start_service("#{proto}://#{a}:#{port}", front, ssl_drb_config)
        end
      end

      private

      def bind_addresses
        intfs.map do |intf|
          case intf
          when '*'
            '0.0.0.0'
          else
            address_for(intf)
          end
        end
      end

      SIOCGIFADDR = 0x8915

      def address_for(intf)
        require 'socket'
        require 'alces/tools/core_ext/string/ipaddr'
        buf = [intf,""].pack('a16h16')
        sock = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM, 0)
        sock.ioctl(SIOCGIFADDR, buf)
        sock.close
        buf[20..23].to_ipaddr4
      end

      def proto
        ssl.nil? ? 'druby' : 'drbssl'
      end
    end
  end
end
