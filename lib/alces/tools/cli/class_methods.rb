################################################################################
# (c) Copyright 2007-2013 Alces Software Ltd & Stephen F Norledge.             #
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
require 'alces/tools/cli/validators'
require 'alces/tools/logging'
require 'alces/tools/auth'
require 'yaml'

module Alces
  module Tools
    module CLI
      module ClassMethods
        include Validators

        def execute
          new.process
        end

        def configfilename(config_filename)
          @__config_filename=config_filename
        end
      
        def get_config_filename
          @__config_filename || "#{@name}.yml"
        end
      
        def config
          begin
            configfile=Alces::Tools::Config.find(get_config_filename)
            @config ||= YAML.load_file(configfile)
            raise unless @config.kind_of? Hash
            @config
          rescue
            raise ConfigFileException, "Problem loading configuration file - #{configfile}"
          end
        end

        def preconditions
          @preconditions ||= []
        end

        def assert_preconditions!
          preconditions.each(&:call)
        end

        def root_only
          preconditions << lambda do
            if ! auth.superuser?
              STDERR.puts "Must be run as superuser"
              exit 1
            end
          end
        end
        
        def auth
          @auth ||= Alces::Tools::Auth.new
        end

        def log_to(log)
          preconditions << lambda do
            log = ::File.expand_path(log) if log.kind_of? String
            @logger = Alces::Tools::Logger.new(log, :progname => @name, :formatter => :full)
            Alces::Tools::Logging.default = @logger
          end
        end
        
        def opts
          if @opts.nil?
            begin
              @opts=self.superclass::opts
            rescue
              @opts={}
            end
          end
          @opts
        end
        
        def add_option_with_argument(*args)
          # XXX - deprecated
          option(*args)
        end
        
        def add_option(*args)
          # XXX - deprecated
          flag(*args)
        end

        def validators_from(args)
          [].tap do |validators|
            if args[:required]
              validators << lambda { |name, val| assert_not_empty(name, val) }
            end
            if args[:file_exists]
              validators << lambda { |name, val| assert_file_exists(name, val) }
            end
            if args[:match]
              validators << lambda { |name, val| assert_match(name, val, args[:match]) }
            end
            if args[:included_in]
              validators << lambda do |name, val| 
                includer = args[:included_in].map {|e| e.to_s.upcase}
                assert_included_in(name, val.to_s.upcase, includer)
              end
            end
            if args[:condition]
              validators << lambda { |name, val| assert_condition(name, val, args[:condition]) }
            end
            if args[:method]
              validators << args[:method].to_sym
            end
          end
        end

        class << self
          def opts_from_args(args)
            if args.length == 1
              args.first
            else
              o = args.last.is_a?(Hash) ? args.pop : {}
              {
                description: args[0],
                long: args[1],
                short: args[2],
                default: args[3]
              }.merge(o)
            end
          end
        end

        def flag(name, *args)
          option(name, ClassMethods.opts_from_args(args).merge(flag: true))
        end

        def option(name, *args)
          o = ClassMethods.opts_from_args(args)
          return if o[:superuser] && ! auth.superuser?
          descriptor = {
            description: o[:description],
            names: [o[:long], o[:short]].compact,
            flag: o[:flag],
            default: o[:default],
            validators: validators_from(o)
          }
          descriptor[:validate_when] = o[:validate_when].to_sym if o.has_key?(:validate_when)
          opts[name.to_s.to_sym] = descriptor
        end
        
        def description(string)
          @description=string
        end

        def name(string)
          @name=string
        end

        def cli_usage
          '[OPTIONS]'
        end

        def usage_text
          t = <<EOF
Synopsis

#{@name}: #{@description}

Usage

#{@name} #{cli_usage}
EOF
          t << opts.map do |opt,h|
            ?\n.tap do |s|
              s << "  #{h[:names].join(", ")}:\n"
              s << "    #{h[:description]}"
              if (d = h[:default])
                s << " [#{d}]" if d.is_a?(String)
              end
            end
          end.join("\n")
        end

        def usage
          puts usage_text
        end
      end
    end
  end
end
