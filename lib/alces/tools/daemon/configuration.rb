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
require 'alces/tools/config'
require 'yaml'

module Alces
  module Tools
    module Daemon
      class Configuration < Struct.new(:interfaces, 
                                       :port,
                                       :log_file,
                                       :configs)
        def initialize(h)
          merge(h)
          load_configs
        end

        def load_configs
          [*configs].each do |cfg|
            send("#{cfg}=",load_config(cfg))
          end
        end

        def load_global_config(cfg)
          if cfg_file = Alces::Tools::Config.find(cfg, false)
            YAML.load_file(cfg_file)
          end
        end

        def load_config(cfg)
          load_global_config(cfg) || YAML.load_file(cfg)
        rescue
          raise ArgumentError, "Unable to load config \'#{cfg}\' - implement #load_config in subclass?"
        end
        
        def merge(config)
          config.each do |k,v|
            send("#{k}=",v)
          end
        end

        module DaemonKit
          def load_config(cfg)
            super
          rescue ArgumentError
            ::DaemonKit::Config.hash(cfg)
          end
        end
        
        module SSL
          class << self
            def included(mod)
              require 'alces/tools/ssl_configurator'
              mod.instance_eval do
                include Alces::Tools::SSLConfigurator
              end
            end
          end

          attr_accessor :ssl
          def ssl=(s)
            @ssl = s.nil? ? nil : Alces::Tools::SSLConfigurator::Configuration.new(s)
          end
        end
      end
    end
  end
end
