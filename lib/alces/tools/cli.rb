################################################################################
# (c) Copyright 2007-2010 Alces Software Ltd & Stephen F Norledge.             #
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

module Alces
  module Tools
    class CLI
      class InvalidCommand < StandardError; end
      class InvalidOption < StandardError; end
      class ConfigFileException < StandardError; end

      class << self
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
          opts[name.to_s.to_sym]=[description,long_flag,short_flag,default_value]
        end
        
        def add_option(name,description,long_flag,short_flag=nil)
          opts[name.to_s.to_sym]=[description,long_flag,short_flag]
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
            puts
            str=""
            str << "#{hsh[1]}, " unless hsh[2].nil?
            str << "#{hsh[2]}:"
            puts str
            str=""
            str << "  #{hsh[0]}"
            if hsh.size > 3
              str << " [#{hsh[3]}]"
            end
            puts str
          end
          puts
        end
      end

      def config
        self.class.config
      end

      def initialize(options={})
        raise TypeError unless options.kind_of? Hash
        @options=options
      end

      add_option :usage, "Show usage", "--help", "-h"
      add_option :verbose, "Be more verbose", "--verbose", "-v"
      description "Description not set"
      name "Name not set"

      def process
        opt_a = []
        self.class.opts.each do |key,hsh|
          opt=[]
          opt << hsh[1] unless hsh[1].to_s.empty?
          opt << hsh[2] unless hsh[2].to_s.empty?
          if hsh.size > 3
            opt << GetoptLong::REQUIRED_ARGUMENT
          else
            opt << GetoptLong::NO_ARGUMENT
          end
          opt_a << opt
        end
        str=''; opt_a.each {|x| str << "#{x.inspect}," }; str.chop!;
        opts = eval "GetoptLong.new(#{str})"
        begin
          set_defaults
          opts.each do |option,arg|
            matching_options=self.class.opts.select { |name,hsh| hsh[1] == option }
            matching_options.each do |x| 
              if self.respond_to? "do_#{x.first}"
                if x.last.size > 3
                  self.send("do_#{x.first}",arg || (x.last[3] rescue nil))
                else
                  self.send("do_#{x.first}")
                end
              else
                unless arg.nil?
                  eval_str="@#{x.first}=\"#{arg}\""
                end
                eval eval_str
              end
            end
          end
          validate_options
          execute
        rescue SystemExit
          nil
        rescue InvalidOption => e
          STDERR.puts "ERROR: #{e.message}"
          exit 1
        rescue Exception => e
          STDERR.puts "ERROR: #{e.message}"
          unless @verbose.to_s.empty?
            STDERR.puts e.backtrace
          end
          exit 1
        end
      end

      def set_defaults
        self.class.opts.each do |name,hsh|
          eval_str="@#{name}=\"#{(hsh[3] rescue nil)}\""
          eval eval_str
        end
      end

      def do_usage
        self.class.usage
        exit 0
      end

      def do_verbose
        @verbose=true
      end
      
      def verbose?
        !@verbose.to_s.empty?
      end

      def execute
        raise "NO EXECUTE METHOD!"
      end
      
      private

      def validate_options
      end

      def validate_not_empty!(option_name,message=nil)
        message="#{option_name} - '#{option_value(option_name)}' is invalid" if message.nil?
        raise InvalidOption, message if option_value(option_name).to_s.empty?
      end

      def option_value(option_name)
        eval_str="@#{option_name}"
        eval eval_str
      end
    end
  end
end
