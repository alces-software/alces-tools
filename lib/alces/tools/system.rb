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

module Alces
  module Tools
    module System
      include Alces::Tools::Execution
      include Alces::Tools::Logging

      OPERATING_SYSTEM_IDENTIFICATION_FILE='/etc/issue'
      OPERATING_SYSTEM_IDENTIFICATION_STRINGS={
        "\nThis is \\n.\\O (\\s \\m \\r) \\t\n\n"=>'DEBIAN_4-0',
        "Ubuntu 7.10 \\n \\l\n\n"=>'DEBIAN_4-0',
        "Debian GNU/Linux 4.0 \\n \\l\n\n"=>'DEBIAN_4-0',
        "Debian GNU/Linux 5.0 \\n \\l\n\n"=>'DEBIAN_5-0',
        "Scientific Linux SL release 5.2 (Boron)\nKernel \\r on an \\m\n\n" => "SCIENTIFIC_LINUX_5-2",
        "CentOS release 5.2 (Final)\nKernel \\r on an \\m\n\n" => "CENTOS_5-2",
	      "CentOS release 5.3 (Final)\nKernel \\r on an \\m\n\n" => "CENTOS_5-3",
	      "CentOS release 5.6 (Final)\nKernel \\r on an \\m\n\n" => "CENTOS_5-6",
        "\nWelcome to openSUSE 10.3 (X86-64) - Kernel \\r (\\l).\n\n\n" => "OPENSUSE_10-3",
        "Red Hat Enterprise Linux Server release 5.3 (Tikanga)\nKernel \\r on an \\m\n\n" => "REDHAT_5-3",
        "CentOS release 5.4 (Final)\nKernel \\r on an \\m\n\n" => "CENTOS_5-4",
        "Scientific Linux SL release 5.5 (Boron)\nKernel \\r on an \\m\n\n" => "SCIENTIFIC_LINUX_5-5",
        "Scientific Linux SL release 5.6 (Boron)\nKernel \\r on an \\m\n\n" => "SCIENTIFIC_LINUX_5-6",
	      "Scientific Linux SL release 5.4 (Boron)\nKernel \\r on an \\m\n\n" => "SCIENTIFIC_LINUX_5-4",
	      "Scientific Linux SL release 5.7 (Boron)\nKernel \\r on an \\m\n\n" => "SCIENTIFIC_LINUX_5-7",
	      "Scientific Linux release 6.1 (Carbon)\nKernel \\r on an \\m\n\n" => "SCIENTIFIC_LINUX_6-1",
	      "\nWelcome to SUSE Linux Enterprise Server 11 SP1  (x86_64) - Kernel \\r (\\l).\n\n" => "SLES_11-1"
      }
      ARCHITECTURE_IDENTIFICATION_STRINGS={
        "x86-64"=>'x86-64',
        "Intel 80386"=>'i386'
      }

      def hostname(opts = {})
        Execution.info('Getting local machine hostname')
        run('/bin/hostname -s', as: lambda {|r| r.stdout.chomp})
      end

      def operating_system
        str=run("cat #{OPERATING_SYSTEM_IDENTIFICATION_FILE}").stdout.chomp
	      info "OS IDENT = #{str.inspect}"
        os=OPERATING_SYSTEM_IDENTIFICATION_STRINGS[str] || 'OTHER'
        os_with_arch="#{os}_#{architecture}"
      end

      def architecture
        res='UNKNOWN'
        ARCHITECTURE_IDENTIFICATION_STRINGS.each do |arch_string,arch|
          if res == "UNKNOWN"
            res=arch if run_bash("file /bin/bash | grep '#{arch_string}'").stdout
          end
        end
	      res
      end
  
      def is_suse?
        return true if operating_system =~ /SUSE/
        return true if operating_system =~ /SLES/
        false
      end

      def is_redhat?
	      return true if operating_system =~ /SCIENTIFIC/
        return true if operating_system =~ /CENTOS/
	      return true if operating_system =~ /REDHAT/
	      false
      end
    end
  end
end
