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
require 'alces/tools/logger'
require 'alces/tools/core_ext/module/delegation'

module Alces
  module Tools
    module Logging
      class << self
        def loggers
          @loggers ||= {
            default: Alces::Tools::Logger.new(STDERR)
          }
        end

        def []=(key, logger)
          loggers[key] = logger
        end

        def [](key)
          loggers[key] || raise("No such logger: #{key}")
        end

        def chain(source, dest = :default)
          loggers[source] = dest
        end

        def method_missing(s,*a,&b)
          if s.to_s[-1] == ?=
            loggers[s.to_s[0..-2].to_sym] = a.first
          else
            loggers.has_key?(s) ? resolve(s) : super
          end
        end

        def included(mod)
          mod.instance_eval do
            extend(ClassMethods)
            include(InstanceMethods)
          end
        end

        private
        def resolve(k)
          case l = loggers[k]
          when Logger
            l
          when Symbol
            resolve(l)
          end
        end
      end

      module InstanceMethods
        class << self
          def included(mod)
            Alces::Tools::Logger::Severity.constants.each do |s|
              s = s.to_s.downcase
              mod.delegate s.to_sym, s[0..0].to_sym, to: mod
            end
          end
        end
      end

      module ClassMethods
        class << self
          def logger_for(mod)
            mod.respond_to?(:log) ? mod.log : STDERR
          end
        end

        def logger=(l)
          @logger = l
        end

        def logger
          @logger ||= Alces::Tools::Logger.new(ClassMethods.logger_for(self))
        end

        def log_format(format)
          formatter = case format
                      when Symbol, String
                        f = format.to_s[0..0].upcase + format.to_s[1..-1].downcase
                        Alces::Tools::Logger::Formatter.const_get(f)
                      when Proc
                        format
                      else
                        if format.respond_to?(:call)
                          format
                        else
                          raise 'Invalid log formatter - must respond to #call'
                        end
                      end
          logger.formatter = formatter
        end

        Alces::Tools::Logger::Severity.constants.each do |s|
          s = s.to_s.downcase
          class_eval <<-EOT, __FILE__, __LINE__ + 1
def #{s}(*a, &b)
  logger.#{s}(*a, &b)
end
alias_method :#{s[0..0]}, :#{s} 
EOT
        end
      end
    end
  end
end
