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
require 'alces/tools/config'
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

            add_option :usage, "Show usage", "--help", "-h"
            add_option :verbose, "Be more verbose", "--verbose", "-v"
            description "Description not set"
            name "Name not set"
          end
        end
      end

      def config
        self.class.config
      end

      def opts
        self.class.opts
      end

      def as_getopts
        opts.map do |key,hsh|
          optargs = hsh[:optargs]
          [].tap do |opt|
            opt << optargs[1] unless optargs[1].to_s.empty?
            opt << optargs[2] unless optargs[2].to_s.empty?
            if optargs.size > 3
              opt << GetoptLong::REQUIRED_ARGUMENT
            else
              opt << GetoptLong::NO_ARGUMENT
            end
          end
        end
      end

      def process
        self.class.assert_preconditions!
        argc = ARGV.length
        getopts = GetoptLong.new(*as_getopts)
        begin
          set_defaults
          getopts.each do |option,arg|
            matching_options = opts.select { |name,hsh| hsh[:optargs][1] == option }
            matching_options.each do |x|
              if respond_to? "do_#{x.first}"
                if x.last.size > 3
                  send("do_#{x.first}",arg || (x.last[3] rescue nil))
                else
                  send("do_#{x.first}")
                end
              else
                instance_variable_set(:"@#{x.first}",arg) unless arg.nil?
              end
            end
          end
          validate_options
          execute
        rescue SystemExit
          nil
        rescue InvalidOption => e
          if argc == 0
            do_usage
          else
            STDERR.puts "ERROR: #{e.message}"
            exit 1
          end
        rescue Exception => e
          STDERR.puts "ERROR: #{e.message}"
          unless @verbose.to_s.empty?
            if e.respond_to?(:reason)
              STDERR.puts "REASON: #{e.reason.to_s}"
            end
            STDERR.puts e.backtrace
          end
          exit 1
        end
      end

      def set_defaults
        opts.each do |name,hsh|
          if hsh[:optargs][3].kind_of? Proc
            default=hsh[:optargs][3].call(self)
          else
            default=hsh[:optargs][3] rescue nil
          end
          instance_variable_set(:"@#{name}",(default))
        end
      end

      def do_usage
        self.class.usage
        exit 0
      end

      def do_verbose
        @verbose = true
      end
      
      def verbose?
        !@verbose.to_s.empty?
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

      def validate_options
        opts.each do |name, descriptor|
          validate_when = descriptor[:validate_when] || "validate_#{name}?".to_sym
          if !respond_to?(validate_when) || send(validate_when)
            validators = descriptor[:validators]
            validators && validators.each do |v|
              case v
              when Proc
                v.call(name,option_value(name))
              when Symbol
                arity = method(v).arity
                send(*[v,name,option_value(name)][0..arity])
              else
                raise "Validator must be a Proc or a Symbol"
              end
            end
          end
        end
      end

      def option_value(option_name)
        instance_variable_get(:"@#{option_name}")
      end
    end
  end
end
