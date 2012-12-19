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
module Alces
  module Tools
    class Patcher
      class << self
        def patch(&block)
          new.tap { |p| p.instance_eval(&block) }.patch!
        end
      end

      Error = Class.new(RuntimeError)

      DEFAULT_WARNER = lambda { |message| STDERR.puts message }

      def initialize
        @location = caller[2]
      end

      def describe(s)
        @description = s
      end

      def fail_message(s)
        @fail_message = s
      end

      def no_raise_on_failure!
        @no_raise = true
      end

      def location(s)
        @location = s
      end

      def patch(&block)
        @patch = block
      end

      def patch_when(&block)
        @condition = block
      end

      def patch_when_not(&block)
        @condition = lambda { !block.call }
      end

      def warner(&block)
        @warner = block
      end

      def patch!
        if should_patch?
          if @description
            (@warner || DEFAULT_WARNER).call(" == MONKEY == #{@description} (#{@location})")
          end
          @patch.call
        else
          failure_message = @failure_message || "Condition failed for: #{@description}"
          if @no_raise
            (@warner || DEFAULT_WARNER).call(" ** OBSOLETE MONKEY ** #{failure_message} (#{@location})")
          else
            raise Error, "#{failure_message} (#{@location})"
          end
        end
      end

      private
      def should_patch?
        return @should_patch if instance_variable_defined?(:@should_patch)
        @should_patch = @condition.nil? || @condition.call
      end        
    end
  end
end
