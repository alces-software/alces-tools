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
require 'tempfile'
require 'alces/tools/core_ext/object/blank'
require 'alces/tools/logging'

module Alces
  module Tools
    module Execution
      class << self
        Alces::Tools::Logging.chain(:execution)
        include Alces::Tools::Logging::ClassMethods
        def logger
          Alces::Tools::Logging.execution
        end
      end

      class Result < Struct.new(:stdout, :stderr, :exit_status, :exc, :value)
        def [](k)
          case k
          when :stdout
            stdout
          when :stderr
            stderr
          when :exit_status
            exit_status
          else
            nil
          end
        end

        def failed!
          @failed = true
        end

        def fail?
          @failed || !exit_status.success?
        end

        def success?
          !fail?
        end

        def outputs
          [].tap do |r|
            r << "Output:\n => #{stdout.split("\n").join("\n => ")}" if stdout.present?
            r << "Error:\n => #{stderr.split("\n").join("\n => ")}" if stderr.present?
          end.join("\n")
        end

        def to_s
          if exc.nil?
            outputs
          else
            "Exception: #{exc.class.name}: #{exc.message}\n => #{exc.backtrace.join("\n => ")}"
          end
        end

        def to_hash
          {
            stdout: stdout,
            stderr: stderr,
            exit_status: exit_status,
            exc: exc,
            value: value
          }
        end

        def to_log
          to_s << "\nExited: " << exit_status.inspect
        end
      end

      class << self
        def cmd_args_from(args)
          cmd_args = args.length == 1 ? args.first : args

          case cmd_args
          when String
            cmd_args = cmd_args.split(" ")
          when Array
            cmd_args
          else
            raise ArgumentError, "invalid argument provided; must be String or Array"
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

      def run_bash(*args, &block)
        opts = Execution.options_from(args)
        raise ":shell option should not be specified when using run_bash" if opts.has_key?(:shell)
        opts[:shell] = '/bin/bash'
        run(*args, opts, &block)
      end
      
      def run_script(*args, &block)
        opts = Execution.options_from(args)
        unless (script = args.shift).is_a?(String)
          raise "run_script should only be used with a String parameter"
        end
        cmd = case ::File::extname(script)
              when '.sh','.bash'
                '/usr/bin/env bash '
              when '.pl','.perl'
                '/usr/bin/env perl '
              when '.rb','.ruby'
                '/usr/bin/env ruby '
              else
                #assume directly executable
                ''
              end
        cmd << script
        run(cmd,opts,&block)
      end
      
      def run(*args, &block)
        opts = Execution.options_from(args)
        cmd_args = Execution.cmd_args_from(args)
        interactive = opts.has_key?(:pty) && opts[:pty]
        spawn_opts = opts[:options] || {}
        spawn_env = opts[:env] || {}

        unless ( shell = opts[:shell] ).nil?
          cmd_args = [shell, *opts[:shell_args], '-c', cmd_args.join(' ')]
        end

        Execution.info("Executing command") do
          [cmd_args.inspect, opts].join(?\n)
        end

        result = Result.new.tap do |r|
          begin
            if interactive
              system(spawn_env, *cmd_args, spawn_opts)
              r.exit_status = $?
            else
              Open3.popen3(spawn_env,*cmd_args,spawn_opts) do |i,o,e,t|
                i.write(opts[:stdin]) if opts[:stdin]
                i.close
                
                # thread reading of stderr alongside reading of
                # stdout as both streams may need to be fully read
                # before they are closed by the process (I'm looking
                # at you wget.)
                Thread.new { r.stderr = opts[:nonblock] ? nonblock_reader(e) : e.read }.tap do |thr|
                  r.stdout = opts[:nonblock] ? nonblock_reader(o) : o.read
                  thr.join
                end

                r.exit_status = t.value
              end
            end
            r.value = as_value(opts[:as],r) if opts.has_key?(:as)
          rescue
            r.failed!
            r.exc = $!
          end
          Execution.debug("Command execution completed"){r}
        end

        block.nil? ? result : block.call(result)
      end

      def nonblock_reader(s)
        ''.tap do |str|
          loop do
            begin
              str << s.read_nonblock(2**8).to_s
            rescue IO::WaitReadable
              IO.select([s])
              retry
            rescue EOFError
              break
            end
          end
        end
      end

      def as_value(as, r)
        case as
        when Symbol
          if r.respond_to?(as)
            r.send(as)
          elsif respond_to?(as)
            send(as, r)
          else
            raise "Value parser '#{as}' could not be found"
          end
        when Proc
          as.call(r)
        else
          raise "Value parsers must be a Symbol or a Proc"
        end
      end

      def value_or_fail(fail_message, opts = {}, &block)
        block.call.tap do |r|
          if opts[:ignore_status]
            # only fail if there's been an exception
            fail(fail_message, r) if r.exc
          else
            fail(fail_message, r) if r.fail?
          end
        end.value
      end

      def fail(message, result = nil)
        super(message)
      end

      def statusly(message,fail_message = nil,&block)
        print message, " "
        block.call.tap do |r|
          if r.fail?
            puts("[\e[31mFAILED\e[0m]")
            fail(fail_message, r) if fail_message
          else 
            puts("[ \e[32mDONE\e[0m ]")
          end
        end
      end  
      
      def with_temp_file(content,&block)
        t = Tempfile.new('alces-temp')
        t.write(content)
        t.fsync
        block.call(t.path)
      ensure
        t.close
        t.unlink
      end
    end
  end
end
