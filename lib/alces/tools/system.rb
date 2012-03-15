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
require 'alces/tools/execution'
require 'alces/tools/core_ext/module/delegation'

module Alces
  module Tools
    module System
      include Alces::Tools::Execution
      extend self

      class Distribution < Struct.new(:title, :abbreviation, :major, :minor)
        class << UNKNOWN = Distribution.new('OTHER','OTHER',0,0)
          def to_s; 'OTHER'; end
          def unknown?
            true
          end
        end
          
        class << self
          def debian(major, minor=0)
            new('DEBIAN', 'DEBIAN', major, minor)
          end
          def sl(major, minor=0)
            new('SCIENTIFIC_LINUX', 'SL', major, minor)
          end
          def centos(major, minor=0)
            new('CENTOS', 'CENTOS', major, minor)
          end
          def rhel(major, minor=0)
            new('REDHAT', 'RH', major, minor)
          end
          def sles(major, minor=0)
            new('SLES', 'SLES', major, minor)
          end

          def for(str)
            name, major, minor = str.upcase.match(/^([A-Z]+)(\d+)[._-](\d+)/).to_a[1..-1]
            raise ArgumentError, "Could not parse '#{str}' to distro" if name.nil? || major.nil? || minor.nil?
            case name
            when 'DEBIAN'
              debian(major, minor)
            when 'SL', 'SCIENTIFIC'
              sl(major, minor)
            when /^CENT(OS)?$/
              centos(major, minor)
            when /^RH(EL)?$/, 'REDHAT'
              rhel(major, minor)
            when 'SLES'
              sles(major, minor)
            else
              new(name, name, major, minor)
            end
          end
        end

        def short_name
          format('%s%V')
        end

        def full_name
          format('%f_%v')
        end

        def pretty_name
          format('%F %V')
        end

        def version
          "#{major}.#{minor}"
        end

        def format(format)
          s = format.dup
          s.gsub!('%f',title)
          s.gsub!('%F',pretty_title)
          s.gsub!('%s',abbreviation)
          s.gsub!('%v',"#{major}-#{minor}")
          s.gsub!('%V',version)
        end
        
        def to_s
          full_name
        end

        def suse?
          abbreviation_in?('SLES','OPENSUSE')
        end

        def redhat?
          abbreviation_in?('RH','SL','CENTOS')
        end

        def debian?
          abbreviation_in?('DEBIAN')
        end

        def unknown?
          false
        end

        private
        def pretty_title
          title.gsub('_',' ').downcase.gsub(/\b([a-z])(\w+)\b/){|s|"#{$1.upcase}#{$2.downcase}"}
        end

        def abbreviation_in?(*args)
          args.include?(abbreviation)
        end
      end

      OPERATING_SYSTEM_IDENTIFICATION_FILE='/etc/issue'
      OPERATING_SYSTEM_IDENTIFICATION_STRINGS={
        "\nThis is \\n.\\O (\\s \\m \\r) \\t\n\n" => Distribution.debian(4),
        "Ubuntu 7.10 \\n \\l\n\n" => Distribution.debian(4),
        "Debian GNU/Linux 4.0 \\n \\l\n\n" => Distribution.debian(4),
        "Debian GNU/Linux 5.0 \\n \\l\n\n" => Distribution.debian(5),
        "Scientific Linux SL release 5.2 (Boron)\nKernel \\r on an \\m\n\n" => Distribution.sl(5,2),
        "CentOS release 5.2 (Final)\nKernel \\r on an \\m\n\n" => Distribution.centos(5,2),
        "CentOS release 5.3 (Final)\nKernel \\r on an \\m\n\n" => Distribution.centos(5,3),
        "CentOS release 5.6 (Final)\nKernel \\r on an \\m\n\n" => Distribution.centos(5,6),
        "\nWelcome to openSUSE 10.3 (X86-64) - Kernel \\r (\\l).\n\n\n" => Distribution.new('OPENSUSE','OPENSUSE',10,3),
        "Red Hat Enterprise Linux Server release 5.3 (Tikanga)\nKernel \\r on an \\m\n\n" => Distribution.rhel(5,3),
        "CentOS release 5.4 (Final)\nKernel \\r on an \\m\n\n" => Distribution.centos(5,4),
        "Scientific Linux SL release 5.5 (Boron)\nKernel \\r on an \\m\n\n" => Distribution.sl(5,5),
        "Scientific Linux SL release 5.6 (Boron)\nKernel \\r on an \\m\n\n" => Distribution.sl(5,6),
        "Scientific Linux SL release 5.4 (Boron)\nKernel \\r on an \\m\n\n" => Distribution.sl(5,4),
        "Scientific Linux SL release 5.7 (Boron)\nKernel \\r on an \\m\n\n" => Distribution.sl(5,7),
        "Scientific Linux release 6.1 (Carbon)\nKernel \\r on an \\m\n\n" => Distribution.sl(6,1),
        "Scientific Linux release 6.2 (Carbon)\nKernel \\r on an \\m\n\n" => Distribution.sl(6,2),
        "\nWelcome to SUSE Linux Enterprise Server 11 SP1  (x86_64) - Kernel \\r (\\l).\n\n" => Distribution.new('SLES','SLES',11,1)
      }

      ARCHITECTURE_IDENTIFICATION_STRINGS={
        "x86-64"=>'x86-64',
        "Intel 80386"=>'i386'
      }

      delegate :suse?, :redhat?, :unknown?, :to => :distro
      # deprecated
      delegate :suse?, :redhat?, :to => :distro, :prefix => :is

      def hostname(opts = {})
        Execution.info('Getting local machine hostname')
        run('/bin/hostname -s', as: lambda {|r| r.stdout.chomp})
      end

      def distro
        @distro ||= begin
                      str = run("cat #{OPERATING_SYSTEM_IDENTIFICATION_FILE}").stdout.chomp
                      Execution.info "OS IDENT = #{str.inspect}"
                      OPERATING_SYSTEM_IDENTIFICATION_STRINGS[str]
                    end || Distribution::UNKNOWN
      end

      def operating_system
        "#{distro}_#{architecture}"
      end

      def architecture
        @arch ||= ( ARCHITECTURE_IDENTIFICATION_STRINGS.find do |arch_string, arch|
                      run_bash("file /bin/bash | grep '#{arch_string}'").stdout
                    end || ['UNKNOWN']).last
      end
    end
  end
end
