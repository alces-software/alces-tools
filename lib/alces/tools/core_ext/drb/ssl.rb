################################################################################
# (c) Copyright 2012 Alces Software Ltd & Stephen F Norledge.                  #
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
require 'drb/ssl'

module DRb
  class DRbSSLSocket
    alias :accept_without_system_call_error_handling :accept
    def accept
      accept_without_system_call_error_handling
    rescue Errno::ECONNRESET
      begin
        Alces::Tools::Logging.default.warn('Received ECONNRESET, handling.'){$!}
      rescue
        warn("#{__FILE__}:#{__LINE__}: warning: #{$!.message} (#{$!.class})")
      end
      retry
    rescue
      begin
        Alces::Tools::Logging.default.error('Uncaught exception within DRb code, about to die.'){$!}
      rescue
        warn("#{__FILE__}:#{__LINE__}: warning: #{$!.message} (#{$!.class})")
      end
      raise
    end
  end
end
