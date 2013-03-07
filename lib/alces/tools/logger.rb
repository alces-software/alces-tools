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
# This file was adapted from activesupport's BufferedLogger.
# For the original, please see: http://bit.ly/rz0O7W
# 
# The original copyright notice follows:
#
# Copyright (c) 2005-2011 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'thread'
require 'fileutils'
require 'alces/tools/throttling_buffer'

module Alces
  module Tools
    # Inspired by the buffered logger idea by Ezra
    class Logger
      module Severity
        DEBUG   = 0
        INFO    = 1
        WARN    = 2
        ERROR   = 3
        FATAL   = 4
        UNKNOWN = 5
      end
      include Severity

      # Adapted from: http://bit.ly/uJfJ9S
      module Formatter
        module Base
          def formatted_time(time)
            # see no need for micro-seconds like in Logger, milis suffices. 
            # No idea why documented %L and other such useful things
            # do not work in strftime. 
            time.strftime("%Y-%m-%d %H:%M:%S.") << time.usec.to_s[0..2].rjust(3)
          end

          def handle_newlines(msg, &block)
            # Rails likes to log with some preceding newlines for spacing in the
            # logfile. We want to preserve those when present, 
            # but prefix actual content with our prefix.
            msg = "" if msg.nil? # regexp won't like nil, but will be okay with ""
            matchData = /^(\n*)/.match(msg)
            matchData[0] + block.call(matchData.post_match)
          end
        end

        module Simple
          FORMAT = "%s [%s]: %s"

          include Base
          extend self

          def call(severity, time, progname, msg)
            handle_newlines(msg) do |msg|
              FORMAT % [severity[0..0], formatted_time(time), msg]
            end
          end
        end

        module Full
          FORMAT = "%s [%s] %s[%d-0x%014x]: %s"

          include Base
          extend self

          def call(severity, time, progname, msg)        
            handle_newlines(msg) do |msg|
              FORMAT % [severity[0..0], formatted_time(time), progname, $$, Thread.current.object_id, msg]
            end
          end
        end
      end
      
      MAX_BUFFER_SIZE = 1000
      
      ##
      # Set to false to disable the silencer
      @@silencer = true
      @@formatter = Formatter::Simple
      class << self
        def silencer=(b); @@silencer = b; end
        def silencer; @@silencer; end
        def default_formatter=(f); @@formatter = f; end
        def default_formatter; @@formatter; end
        def formatter_for(f)
          case f
          when Formatter::Base
            f
          when :simple
            Formatter::Simple
          when :full
            Formatter::Full
          when NilClass
            nil
          else
            raise "Unrecognised formatter: #{f}"
          end
        end
      end
      
      # Silences the logger for the duration of the block.
      def silence(temporary_level = ERROR)
        if @@silencer
          old_logger_level = @tmp_levels[Thread.current]
          begin
            @tmp_levels[Thread.current] = temporary_level
            yield self
          ensure
            if old_logger_level
              @tmp_levels[Thread.current] = old_logger_level
            else
              @tmp_levels.delete(Thread.current)
            end
          end
        else
          yield self
        end
      end

      attr_writer :level
      attr_reader :auto_flushing
      attr_accessor :formatter

      def initialize(log, opts = {})
        if opts.is_a?(Hash)
          @level = opts[:level] || DEBUG
        else
          @level = opts
          opts = {}
        end
        @tmp_levels    = {}
        @buffer        = Hash.new { |h,k| h[k] = ThrottlingBuffer.new }
        # This will flush after every message has been received. To activate
        # both buffering and throttling set this to a number greater than 1.
        # There is currently no mechanism to buffer without throttling.
        @auto_flushing = 1
        @guard = Mutex.new

        if log.respond_to?(:write)
          @log = log
        elsif File.exist?(log)
          @log = open_log(log, (File::WRONLY | File::APPEND))
        else
          FileUtils.mkdir_p(File.dirname(log))
          @log = open_log(log, (File::WRONLY | File::APPEND | File::CREAT))
        end

        @formatter = self.class.formatter_for(opts[:formatter])
        @cleaner = opts[:cleaner]
        @progname = opts[:progname]
      end

      def open_log(log, mode)
        open(log, mode).tap do |open_log|
          open_log.set_encoding(Encoding::BINARY) if open_log.respond_to?(:set_encoding)
          open_log.sync = true
        end
      end

      def level
        @tmp_levels[Thread.current] || @level
      end

      def add(severity, message = nil, progname = nil, &block)
        return if level > severity
        if message && block
          message = render_message(message)
          block_parts = render_message(block.call).split("\n",-1)
          message << ?\n << render_sub_message(block_parts)
        else
          message = render_message(message || (block && block.call))
        end
        formatted_message = format_message(severity, Time.now, progname, message)

        # If a newline is necessary then create a new message ending with a newline.
        # Ensures that the original message is not mutated.
        formatted_message = "#{formatted_message}\n" unless formatted_message[-1] == ?\n
        buffer << [message, formatted_message]
        auto_flush
        formatted_message
      end

      # Dynamically add methods such as:
      # def info
      # def warn
      # def debug
      Severity.constants.each do |severity|
        class_eval <<-EOT, __FILE__, __LINE__ + 1
        def #{severity.downcase}(message = nil, progname = nil, &block) # def debug(message = nil, progname = nil, &block)
          add(#{severity}, message, progname, &block)                   #   add(DEBUG, message, progname, &block)
            end                                                             # end

      def #{severity.downcase}?                                       # def debug?
        #{severity} >= level                                         #   DEBUG >= @level
      end                                                             # end
      EOT
    end

    # Set the auto-flush period. Set to true to flush after every log message,
    # to an integer to flush every N messages, or to false, nil, or zero to
    # never auto-flush. If you turn auto-flushing off, be sure to regularly
    # flush the log yourself -- it will eat up memory until you do.
    def auto_flushing=(period)
      @auto_flushing =
        case period
        when true;                1
        when false, nil, 0;       MAX_BUFFER_SIZE
        when Integer;             period
        else raise ArgumentError, "Unrecognized auto_flushing period: #{period.inspect}"
        end
    end

    def flush
      @guard.synchronize do
        write_buffer(buffer)

        # Important to do this even if buffer was empty or else @buffer will
        # accumulate empty arrays for each request where nothing was logged.
        clear_buffer

        # Clear buffers associated with dead threads or else spawned threads
        # that don't call flush will result in a memory leak.
        flush_dead_buffers
      end
    end

    # Flush each buffer and remove it from the @buffer hash.
    def flush_all
      @guard.synchronize do
        @buffer.keys.each do |thread|
          buffer = @buffer[thread]
          write_buffer(buffer)
          @buffer.delete(thread)
        end
      end
    end

    def close
      flush
      @log.close if @log.respond_to?(:close)
      @log = nil
    end

    protected
    
    SEV_LABEL = %w(DEBUG INFO WARN ERROR FATAL UNKNOWN)
    def format_severity(severity)
      SEV_LABEL[severity] || 'UNKNOWN'
    end
    
    def format_message(severity, datetime, progname, msg)
      if formatter = (@formatter || self.class.default_formatter)
        progname ||= @progname || $0
        formatter.call(format_severity(severity), datetime, progname, msg)
      else
        msg
      end
    end

    def render_sub_message(parts, klass = nil)
      if klass
        l = 68 - klass.name.length
        l = 0 if l < 0
        " \\----[ #{klass.name} ]#{'-' * l}/"
      else
        " \\#{'-' * 76}/"
      end <<
        ([nil] + parts || []).join("\n | ") <<
        "\n /#{'-' * 76}\\"
    end

    def clean(backtrace)
      @cleaner.nil? ? backtrace : @cleaner.clean(backtrace)
    end

    def render_message(msg)
      case msg
      when ::String
        msg
      when ::Exception
        "{Exception} #{msg.message}\n#{render_sub_message(clean(msg.backtrace), msg.class)}"
      else
        if msg.respond_to?(:to_log)
          msg.to_log
        elsif msg.respond_to?(:inspect)
          "<#{msg.class.name}:#{'0x%014x' % msg.__id__}> #{msg.inspect}"
        else
          "<#{msg.class.name}:#{'0x%014x' % msg.__id__}> #{msg.to_s}"
        end
      end
    rescue
      "<#{msg.class.name rescue 'class!'}:#{('0x%014x' % msg.class.object_id) rescue '__id__!'}> Unrenderable object!"
    end

    def auto_flush
      flush if buffer.size >= @auto_flushing
    end

    def buffer
      @buffer[Thread.current]
    end

    def clear_buffer
      @buffer.delete(Thread.current)
    end

    # Find buffers created by threads that are no longer alive and flush them to the log
    # in order to prevent memory leaks from spawned threads.
    def flush_dead_buffers #:nodoc:
      @buffer.keys.reject{|thread| thread.alive?}.each do |thread|
        buffer = @buffer[thread]
        write_buffer(buffer)
        @buffer.delete(thread)
      end
    end

    def write_buffer(buffer)
      buffer.each do |content|
        @log.write(content)
      end
    end
  end
end
end

