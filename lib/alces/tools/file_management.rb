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
require 'alces/tools/core_ext/object/blank'
require 'alces/tools/fileutils_proxy'
require 'alces/tools/execution'
require 'alces/tools/logging'
require 'digest/md5'

module Alces
  module Tools
    module FileManagement
      class << self
        Alces::Tools::Logging.chain(:file_management)
        include Alces::Tools::Logging::ClassMethods
        def logger
          Alces::Tools::Logging.file_management
        end

        def metadata_filename(filename, metadata_dir, ext)
          File.expand_path(File.join([File.dirname(filename),
                                      metadata_dir,
                                      "#{File.basename(filename)}.#{ext}"].compact))
        end

        def match?(filename, metadata_dir, ext)
          md5_fn = metadata_filename(filename, metadata_dir, ext)
          if !File.exists?(md5_fn)
            true
          else
            md5 = Digest::MD5.hexdigest(File.read(filename))
            # check current md5 against stored version
            original_md5 = File.read(md5_fn).chomp
            FileManagement.debug "MD5 check - original: #{original_md5}; current: #{md5}"
            md5 == original_md5
          end
        end
      end

      include Alces::Tools::Execution
 
      delegate :read, to: File
      delegate :mkdir, :mkdir_p, :chmod, :chown, :rm, :rm_r, :rm_rf, :rm_f,
               :ln, :ln_s, :ln_sf, :touch, 
               :cp, :cp_r,
               to: FileUtilsProxy

      def write(filename, data, opts = {})
        FileManagement.info("Writing file #{filename}")
        File.open(filename,'wb') do |f|
          f.write(data)
        end
        chmod(opts[:mode],filename) if opts[:mode]
        File::exists?(filename)
      end

      def write_parts(filename, *parts)
        opts = Alces::Tools::Execution.options_from(parts)
        data = parts.shift
        parts.each do |p|
          data << ?\n unless data[-1] == ?\n
          data << p
        end
        write(filename, data, opts)
      end

      def append(filename, suffix, opts = {})
        raise "Filename is blank" if filename.blank?
        FileManagement.info("Appending to #{filename}")
        write_parts(filename, read(filename), suffix, opts)
      end
      
      def prepend(filename, prefix, opts = {})
        raise "Filename is blank" if filename.blank?
        FileManagement.info("Prepending to #{filename}")
        write_parts(filename, prefix, read(filename), opts)
      end
      
      def patch(filename, patch_data)
        FileManagement.info("Patching #{filename}")
        run("patch -p0 #{filename}", stdin: patch_data)
      end

      def grep_q(filename, pattern)
        FileManagement.info("Grepping #{filename} for #{pattern}")
        res = run("grep -q #{pattern} #{filename}")
        res[:exit_status].success?
      end

      def backup(filename, ext='alcesbackup', metadata_dir='.alces')
        raise "Filename is blank" if filename.blank?
        if File.exists?(filename)
          bfn = FileManagement.metadata_filename(filename, metadata_dir, ext)
          FileManagement.info("Backing up #{filename} to #{bfn}")
          mkdir_p(File::dirname(bfn)) rescue nil
          run("cp -pavf #{filename} #{bfn}").success?
        else
          true
        end
      end

      def restore(filename, ext='alcesbackup', metadata_dir='.alces')
        raise "Filename is blank" if filename.blank?
        bfn = FileManagement.metadata_filename(filename, metadata_dir, ext)
        FileManagement.info("Restoring #{filename} from backup (#{bfn})")
        if File.exists?(bfn)
          rm(filename) rescue nil
          run("cp -pavf #{bfn} #{filename}").success?
        else
          false
        end
      end

      def if_unchanged(filename, force=false, *args, &block)
        if verify_md5(filename, force, *args)
          block.call(filename, File.exists?(filename))
          write_md5(filename, *args)
        else
          false
        end
      end

      def verify_md5(filename, force=false, ext='md5sum', metadata_dir='.alces')
        raise "Filename is blank" if filename.blank?
        FileManagement.info "Performing MD5 verification for #{filename}"
        force || !File.exists?(filename) || 
          FileManagement.match?(filename, metadata_dir, ext)
      end

      def write_md5(filename, metadata_dir='.alces', ext='md5sum')
        md5_fn = FileManagement.metadata_filename(filename, metadata_dir, ext)
        mkdir_p(File.dirname(md5_fn))
        write(md5_fn, Digest::MD5.hexdigest(read(filename)))
      end
    end
  end
end
