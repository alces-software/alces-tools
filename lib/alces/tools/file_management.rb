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
require 'alces/tools/core_ext/module/delegation'
require 'alces/tools/fileutils_proxy'
require 'alces/tools/execution'

module Alces
  module Tools
    module FileManagement
      include Alces::Tools::Execution

      def write(dest_filename,data, opts = {})
        File.open(dest_filename,'wb') do |f|
          f.write(data)
        end
        chmod(opts[:mode],dest_filename) if opts[:mode]
        File::exists? dest_filename
      end
      
      def read(src_filename)
        return File::read(src_filename)
      end
      
      def patch(dest_filename, patch_data)
        run("patch -p0 #{dest_filename}", stdin: patch_data)
      end

      def grep_q(filename, pattern)
        res = run("grep -q #{pattern} #{filename}")
        res[:exit_status].success?
      end

      delegate :mkdir, :mkdir_p, :chmod, :rm, :rm_r, :rm_rf, :rm_f, :ln, :ln_s, :ln_sf, :touch, to: FileUtilsProxy
    end
  end
end
