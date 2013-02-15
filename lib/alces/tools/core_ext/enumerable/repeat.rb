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
module Enumerable
  # Return an enumerator in which each element of enum is repeated n times.
  #
  #     (1..5).repeat(2).to_a #=> [1,1,2,2,3,3,4,4,5,5]
  #     (1..5).repeat(3).to_a #=> [1,1,1,2,2,2,3,3,3,4,4,4,5,5,5]
  #
  # Contrast with  Enumerable#cycle
  #
  #     (1..5).cycle(2).to_a #=> [1,2,3,4,5,1,2,3,4,5]
  #
  def repeat(n)
    return self if n < 0
    Enumerator.new do |yielder|
      each do |obj|
        n.times do
          yielder.yield(obj)
        end
      end
    end
  end
end
