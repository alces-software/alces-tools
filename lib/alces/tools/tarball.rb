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
require 'zlib'
require 'rubygems/package'

module Alces
  module Tools
    module Tarball
      # un-gzips the given IO, returning the
      # decompressed version as a StringIO
      def ungzip_io(io)
        z = Zlib::GzipReader.new(io)
        unzipped = StringIO.new(z.read)
        z.close
        unzipped
      end
      
      # untars the given IO into a hash of "files"
      def untar_io(io)
        {}.tap do |files|
          Gem::Package::TarReader.new(io) do |tar|
            tar.each do |tarfile|
              content = tarfile.directory? ? :directory : tarfile.read
              files[tarfile.full_name.gsub(/^\.\//,'')] = content || ''
            end
          end
        end
      end

      def untar(o)
        case o
        when ::File
          if ['.gz','.tgz'].include?(::File.extname(o.path))
            untar_io(ungzip_io(o))
          else
            untar_io(o)
          end
        when String
          untar(::File.new(o))
        when IO
          untar_io(o)
        else
          raise ArgumentError, "invalid argument; requires IO, File or String"
        end
      end
    end
  end
end
