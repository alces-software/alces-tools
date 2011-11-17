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
require 'getoptlong'
require 'alces/tools/core_ext/module/delegation'
require 'alces/tools/core_ext/object/blank'
require 'alces/tools/cli/class_methods'

module Alces
  module Tools
    module CLI
      class InvalidCommand < StandardError; end
      class InvalidOption < StandardError; end
      class ConfigFileException < StandardError; end

      class << self
        def included(mod)
          mod.instance_eval do
            extend ClassMethods
            
            flag :usage, 
                 'Show usage',
                 '--help', '-h'

            flag :verbose, 
                 'Be more verbose',
                 '--verbose', '-v'

            description "Description not set"
            name "Name not set"
            log_to STDERR

            delegate :config, :opts, :usage, :assert_preconditions!, to: self
          end
        end

        def getopts_from(opts)
          o = opts.map do |key,h|
            [].tap do |opt|
              opt.concat(h[:names])
              opt << (h[:flag] ? GetoptLong::NO_ARGUMENT : GetoptLong::REQUIRED_ARGUMENT)
            end
          end
          GetoptLong.new(*o)
        end
      end

      def process
        assert_preconditions!
        argc = ARGV.length
        set_defaults
        process_options
        validate_options
        execute
      rescue SystemExit
        nil
      rescue InvalidOption => e
        do_usage if argc == 0
        STDERR.puts "ERROR: #{e.message}"
        exit 1
      rescue Exception => e
        STDERR.puts "ERROR: #{e.message}"
        if verbose?
          STDERR.puts "REASON: #{e.reason.to_s}" if e.respond_to?(:reason)
          STDERR.puts e.backtrace
        end
        exit 1
      end

      def do_usage
        usage
        exit 0
      end

      def do_verbose
        @verbose = true
      end
      
      def verbose?
        @verbose.present?
      end

      def execute
        raise "NO EXECUTE METHOD!"
      end
      
      def method_missing(s,*a,&b)
        isym = "@#{s}".to_sym
        if instance_variable_defined?(isym)
          instance_variable_get(isym)
        else
          super
        end
      end

      private

      def set_defaults
        opts.each do |name,h|
          d = h[:default]
          self[name] = d.is_a?(Proc) ? d.call(self) : d
        end
      end

      def process_options
        CLI.getopts_from(opts).each do |option,arg|
          name, h = opts.find { |k,v| v[:names].include?(option) }
          doer = "do_#{name}"
          if respond_to?(doer)
            args = h[:flag] ? [] : [arg, self[name]].flatten
            send(doer, *args)
          else
            self[name] = h[:flag] || arg
          end
        end
      end

      def validate_options
        opts.each do |name, descriptor|
          validate_when = descriptor[:validate_when] || "validate_#{name}?".to_sym
          if !respond_to?(validate_when) || send(validate_when)
            validators = descriptor[:validators]
            validators && validators.each do |v|
              case v
              when Proc
                v.call(name,self[name])
              when Symbol
                arity = method(v).arity
                send(*[v,name,self[name]][0..arity])
              else
                raise "Validator must be a Proc or a Symbol"
              end
            end
          end
        end
      end

      def [](name)
        instance_variable_get(:"@#{name}")
      end

      def []=(name, val)
        instance_variable_set(:"@#{name}", val)
      end
    end
  end
end
