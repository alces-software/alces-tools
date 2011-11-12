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
require 'alces/tools/cli/validators'

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
          @__config_filename || "#{::File::basename(__FILE__)}.yml"
        end
      
        def config
          begin
            configfile=Alces::Tools::Config::find(get_config_filename)
            @config ||= YAML::load_file(configfile)
            raise unless @config.kind_of? Hash
            @config
          rescue
            raise ConfigFileException, "Problem loading configuration file - #{configfile}"
          end
        end

        def root_only
          if ENV['USER'] != 'root'
            STDERR.puts "Must be run as superuser"
            exit 1
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
        
        def add_option_with_argument(name,description,long_flag,short_flag=nil,default_value=nil)
          opts[name.to_s.to_sym] = {
            optargs: [description,long_flag,short_flag,default_value]
          }
        end
        
        def add_option(name,description,long_flag,short_flag=nil)
          opts[name.to_s.to_sym] = {
            optargs: [description,long_flag,short_flag]
          }
        end

        def validators_from(args)
          [].tap do |validators|
            if args[:required]
              (args[:required][:value] rescue args[:required]) && validators << { proc: lambda { |name, val| assert_not_empty(name, val)}, 
                                                                                  conditions: (args[:required][:conditions] rescue nil) }
            end
            if args[:file_exists]
              validators << { proc: lambda { |name, val| assert_file_exists(name, val)}}
            end
            if args[:match]
              validators << { proc: lambda { |name, val| assert_match(name, val, args[:match]) } }
            end
            if args[:included_in]
              validators << { proc: lambda { |name, val| assert_included_in(name, val, args[:included_in] ) } }
            end
          end
        end

        def option(name, args)
          optargs = [args[:description], args[:long], args[:short]]
          optargs << args[:default] unless args[:flag]
          descriptor = {
            optargs: optargs,
            validators: validators_from(args)
          }
          opts[name.to_s.to_sym] = descriptor
        end
        
        def description(string)
          @description=string
        end

        def name(string)
          @name=string
        end

        def usage
          puts "Synopsis"
          puts
          puts "#{@name}: #{@description}"
          puts
          puts "Usage"
          puts
          puts "#{@name} [OPTION]"
          opts.each do |opt,hsh|
            optargs = hsh[:optargs]
            puts
            str=""
            str << "#{optargs[1]}, " unless optargs[2].nil?
            str << "#{optargs[2]}:"
            puts str
            str=""
            str << "  #{optargs[0]}"
            if optargs.size > 3
              str << " [#{optargs[3]}]"
            end
            puts str
          end
          puts
        end
      end
    end
  end
end
