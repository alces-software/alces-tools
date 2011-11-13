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
require 'open3'

module Alces
  module Tools
    module Execution
      class << self
        def cmd_args_from(args)
          cmd_args = args.length == 1 ? args.first : args

          case cmd_args
          when String
            cmd_args = [cmd_args]
          when Array
            # no op
          else
            raise ArgumentError, "execute only understands String and Array arguments"
          end
        end

        def options_from(args)
          opts = args.pop
          unless opts.is_a?(Hash)
            args << opts
            opts = {}
          end
          opts
        end
      end

      def run(*args)
        opts = Execution.options_from(args)
        cmd_args = Execution.cmd_args_from(args)
        spawn_opts = opts[:options] || {}
        spawn_env = opts[:env] || {}

        shell = opts[:shell]
        cmd_args = [shell, '-c', cmd_args.join(' ')] unless shell.nil?
 
        {}.tap do |ret|
          Open3.popen3(spawn_env,*cmd_args,spawn_opts) do |i,o,e,t|
            i.write(opts[:stdin]) if opts[:stdin]
            i.close
            
            ret[:stdout] = o.read
            ret[:stderr] = e.read
            ret[:exit_status] = t.value
          end
        end
      end
    end
    module InteractiveExecution
      include Execution
      
      VALID_MODES = [:BACKGROUND,:FOREGROUND]
      
      def run(*args)
        opts= Execution.options_from(args)
        mode=opts[:mode] ||= :BACKGROUND
        opts[:text] && opts[:text] << " " || opts[:text]="Execution command "
        
        begin
          if mode == :FOREGROUND
            #TODO - no time to figure out how do this with popen3, do this properly at some point and preseve the args. 
            cmd_args=Execution.cmd_args_from(args)
            shell=opts[:shell]
            cmd_args = [shell, '-c', cmd_args.join(' ')] unless shell.nil?
            res={}.tap { |res|
              res[:exit_status]=system(*cmd_args.join(" "))
            }
          else
            print opts[:text]
            res=super(*args)
            res[:exit_status]=res[:exit_status].success?
          end
        rescue
          res = {:exit_status=>false}
        end
        res[:exit_status] ? puts("[ \e[32mDONE\e[0m ]") : puts("[\e[31mFAILED\e[0m]")
        res
      end
    end
  end
end
