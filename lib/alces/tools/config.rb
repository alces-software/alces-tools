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
module Alces
  module Tools
    module Config
      LOCAL_CONFIG_BASE=::File::join('/etc/opt/alces/')
      SHARED_CONFIG_BASE=::File::join('/opt/gridware/etc/opt/alces/')
      
      class << self
        #Find a config file using the 3 Alces locations in sequence -> LOCAL, SHARED, GEM
        def find(name)
          configfile = local(name)
          unless ::File::exists?(configfile)
            configfile = shared(name)
            unless ::File::exists?(configfile)
              configfile = gem(name)
            end
          end
          configfile
        end
        
        #return the path of the file as if it was local config
        def local(name)
          ::File::join(LOCAL_CONFIG_BASE,name)
        end
    
        #return the path of the file as if it was shared config
        def shared(name)
          ::File::join(SHARED_CONFIG_BASE,name)
        end
        
        #return the path of the file as if it was gem config
        def gem(name)
          ::File::join(::File::dirname(::File::expand_path($0)),"../config/#{name}")
        end
      end
    end
  end
end

