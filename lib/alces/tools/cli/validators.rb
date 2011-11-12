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
    module CLI
      module Validators
        def assertion(condition, key, *args)
          raise InvalidOption, message(key, *args) unless condition.call
        end
        
        def assert_not_empty(name, value, conditions=nil)
          assertion(-> { !value.to_s.empty? }, :not_present, name, value )
        end
        
        def assert_file_exists(name, value)
          assertion(-> { ::File::exists?(value) }, :no_such_file, name, value)
        end
        
        def assert_match(name, value, regexp)
          assertion(-> { value =~ Regexp.new(regexp) }, :match_failed, name, value, regexp)
        end

        def assert_included_in(name, value, array)
          assertion(-> { array.include? value }, :not_valid, name, value, array)
        end

        def message(key, *args)
          case key
          when :no_such_file
            "%s: File does not exist: %s" % args
          when :not_valid
            "%s: '%s' is not a valid selection" %args
          else
            "%s: '%s' is invalid" % args
          end
        end
      end
    end
  end
end
