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
require 'openssl'

module Alces
  module Tools
    module SSLConfigurator
      class Configuration < Struct.new(:certificate,
                                       :key,
                                       :ca,
                                       :root)
        def initialize(h)
          h.each do |k,v|
            self[k] = v
          end
        end
      end

      SSL_CONTEXT_MAP = {
        :cert= => :SSLCertificate,
        :key= => :SSLPrivateKey,
        :ca_file= => :SSLCACertificateFile,
        :verify_mode= => :SSLVerifyMode,
        :verify_callback= => :SSLVerifyCallback
      }

      def ssl
        super 
      rescue NoMethodError
        raise(NotImplementedError, "Includers must implement #ssl returning an SSLConfigurator::Configuration object")
      end

      def ssl?
        !ssl.nil?
      end

      def ssl_cert
        cert_file = ssl_path_to_file(ssl.certificate)
        OpenSSL::X509::Certificate.new(File.read(cert_file))
      end

      def ssl_key
        key_file = ssl_path_to_file(ssl.key)
        OpenSSL::PKey::RSA.new(File.read(key_file))
      end

      def ssl_ca_file
        ssl_path_to_file(ssl.ca)
      end

      def ssl_verify_mode
        OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
        # OpenSSL::SSL::VERIFY_NONE
      end

      def ssl_verify_certificate(preverify_ok, ssl_context)
        if preverify_ok != true || ssl_context.error != 0
          warn "SSL Verification failed -- Preverify: #{preverify_ok}, Error: #{ssl_context.error_string} (#{ssl_context.error})"
          err_msg = "SSL Verification failed -- Preverify: #{preverify_ok}, Error: #{ssl_context.error_string} (#{ssl_context.error})"
          # mjt - no longer works as of 1.9.3, but as it's an OSX local issue, this is surely fine (see #ssl_config below).
          raise OpenSSL::SSL::SSLError.new(err_msg)
          false
        else
          true
        end
      end

      def ssl_config
        {
          SSLCertificate: ssl_cert,
          SSLPrivateKey: ssl_key,
          SSLCACertificateFile: ssl_ca_file, 
          SSLVerifyMode: ssl_verify_mode,
          # http://www.braintreepayments.com/devblog/sslsocket-verify_mode-doesnt-verify
          # http://redmine.ruby-lang.org/issues/3150
          # mjt - possibly only an issue while developing on OSX, but an issue nonetheless :-/
          # XXX - VERIFY PEER CERTIFICATE A BIT MORE?
          :SSLVerifyCallback => lambda { |preverify_ok, ssl_context| ssl_verify_certificate(preverify_ok, ssl_context) }
        }
      end

      # create an SSL configuration suitable for starting up a DRb service (server side)
      def ssl_drb_config
        return unless ssl?
        ::DRb.config.dup.
          merge!(ssl_config)
      end

      # affect DRb environment with this SSL configuration (client side)
      def ssl_drb_config!
        return unless ssl?
        require 'drb/ssl'
        # XXX - the following doesn't work :-/
        ::DRb.config.merge!(ssl_config)
        # XXX - fallback to this approach for now
        ::DRb.start_service nil, nil, ssl_config
      end

      def ssl_context
        @ssl_context ||= ssl_context!
      end

      def ssl_context!
        cfg = ssl_config
        @ssl_context = OpenSSL::SSL::SSLContext.new.tap do |ctx|
          SSL_CONTEXT_MAP.each do |msg, cfg_key|
            ctx.send(msg, cfg[cfg_key])
          end
        end
      end

      def ssl_socket(socket)
        OpenSSL::SSL::SSLSocket.new(socket, ssl_context).tap do |sock|
          sock.sync_close = true
          sock.connect
          # XXX - VERIFY PEER CERTIFICATE A BIT MORE?
          # STDERR.puts sock.peer_cert.to_s
        end
      end

      def ssl_server(server)
        OpenSSL::SSL::SSLServer.new(server, ssl_context)
      end

      def ssl_path_to_file(f)
        case f[0..0]
        when '/'
          f
        when '~'
          File.expand_path(f)
        else
          if ssl.root.nil?
            File.expand_path(f)
          else
            File.join(ssl.root, f)
          end
        end
      end
    end
  end
end
