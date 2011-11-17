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
require 'fileutils'

module Alces
  module Tools
    module FileUtilsProxy
      class << self
        def log_errors!
          @errors = :log
        end
        
        def raise_errors!
          @errors = :raise
        end
        
        def silence_errors!
          @errors = :silent
        end
        
        def method_missing(s, *a, &b)
          if FileUtils.respond_to?(s)
            begin
              FileManagement.info("Performing FileUtils.#{s} with args #{a.inspect}")
              FileUtils.send(s, *a, &b) && true
            rescue
              case @errors
              when :log, :raise
                FileManagement.warn("Failed: FileUtils.#{s} with args #{a.inspect}"){$!}
                raise $! if @errors == :raise
              end
              false
            end
          else
            super
          end
        end
      end
      raise_errors!
    end
  end
end
