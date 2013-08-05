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
require 'alces/tools/logging'
require 'alces/tools/daemon/configuration'
require 'yaml'

module Alces
  module Tools
    module Daemon
      module ClassMethods
        def setup!(&block)
          block.call(self)
          logger
          self
        end

        def find_config(name)
          if config_file = Alces::Tools::Config.find(name, false)
            YAML.load_file(config_file)
          elsif defined?(DaemonKit)
            DaemonKit::Config.hash(name, true)
          end
        end

        def load_config(name)
          self.config = (find_config(name) || {})
        end

        def logger
          @logger ||= begin
                        Alces::Tools::Logging.default = 
                          Alces::Tools::Logger.new(config.log_file || STDERR, 
                                                   formatter: :full)
                      end
        end

        def config=(cfg)
          @config = self::Configuration.new(default_config.merge(cfg))
        end

        def config
          @config ||= self::Configuration.new(default_config)
        end
      
        def default_config
          {
            interfaces: ['*']
          }
        end
      end
    end
  end
end
