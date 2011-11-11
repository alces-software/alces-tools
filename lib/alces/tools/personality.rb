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
    class Personality
      class MalformedPersonalityError < StandardError; end

      REQUIRED_DATA = %W(
ssl/ssl.conf ssl/apache_crt.pem ssl/apache_key.pem ssl/shorewall-rules.patch
)
      attr_accessor :data

      def initialize(data)
        self.data = data
        assert_validity!
      end

      def datum(key)
        data[key]
      end
      alias :[] :datum

      private
      def assert_validity!
        # ensure all required data are present
        REQUIRED_DATA.each do |f|
          raise MalformedPersonalityError, "required personality data '#{f}' not found" unless data.has_key?(f)
        end
      end
    end
  end
end
