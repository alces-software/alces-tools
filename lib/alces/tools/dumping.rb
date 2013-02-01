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
module Alces
  module Tools
    module Dumping
      class << self
        def included(mod)
          mod.extend(ClassMethods)
          mod.instance_eval do
            define_method(:_dump) do |level|
              self.class._dumping_mutex.synchronize do
                mod._normal_dump do
                  begin
                    Marshal.dump(self, level)
                  rescue TypeError
                    raise unless $!.message == 'no _dump_data is defined for class Proc'
                    warn "Standard Marshal.dump failed, falling back for #{mod.name}"
                    "[F]" << _fallback_dump
                  end
                end
              end
            end

            def _load(data,*a)
              if data[0..2] == '[F]'
                _fallback_load(data[3..-1])
              else
                _dumping_mutex.synchronize do
                  self._normal_load do
                    Marshal.load(data,*a)
                  end
                end
              end
            end
            
            def respond_to?(s,*)
              if s == :_load
                begin
                  _dumping_mutex.synchronize { true }
                rescue ThreadError
                  # Recursive locking attempt, means we've hit
                  # #respond_to? during a mutex, so we have removed
                  # the method.
                  super
                end
              else
                super
              end
            end
          end
        end
      end

      def respond_to?(s,*)
        if s == :_dump
          begin
            self.class._dumping_mutex.synchronize { true }
          rescue ThreadError
            # Recursive locking attempt, means we've hit #respond_to?
            # during a mutex, so we have removed the method.
            super
          end
        else
          super
        end
      end

      def _fallback_dump
        raise NotImplementedError, 'Implement #_fallback_dump!'
      end

      module ClassMethods
        def _dumping_mutex
          @_duping_mutex ||= Mutex.new
        end

        def _normal_load(&block)
          singleton = (class << self;self;end)
          _load = method(:_load)
          singleton.send(:remove_method,:_load)
          block.call
        ensure
          singleton.send(:define_method,:_load,_load)
        end
        
        def _fallback_load(data)
          raise NotImplementedError, 'Implement ::_fallback_load'
        end

        def _normal_dump(&block)
          _dump = instance_method(:_dump)
          remove_method(:_dump)
          block.call
        ensure
          define_method(:_dump,_dump)
        end
      end
    end
  end
end
