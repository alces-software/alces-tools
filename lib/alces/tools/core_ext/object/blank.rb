# -*- coding: utf-8 -*-
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
# This file was shamelessly borrowed from activesupport.
# For the original, please see: http://bit.ly/slZ6QW
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

class Object
  # An object is blank if it's false, empty, or a whitespace string.
  # For example, "", "   ", +nil+, [], and {} are all blank.
  #
  # This simplifies:
  #
  #   if address.nil? || address.empty?
  #
  # ...to:
  #
  #   if address.blank?
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  # An object is present if it's not <tt>blank?</tt>.
  def present?
    !blank?
  end

  # Returns object if it's <tt>present?</tt> otherwise returns +nil+.
  # <tt>object.presence</tt> is equivalent to <tt>object.present? ? object : nil</tt>.
  #
  # This is handy for any representation of objects where blank is the same
  # as not present at all. For example, this simplifies a common check for
  # HTTP POST/query parameters:
  #
  #   state   = params[:state]   if params[:state].present?
  #   country = params[:country] if params[:country].present?
  #   region  = state || country || 'US'
  #
  # ...becomes:
  #
  #   region = params[:state].presence || params[:country].presence || 'US'
  def presence
    self if present?
  end
end

class NilClass
  # +nil+ is blank:
  #
  #   nil.blank? # => true
  #
  def blank?
    true
  end
end

class FalseClass
  # +false+ is blank:
  #
  #   false.blank? # => true
  #
  def blank?
    true
  end
end

class TrueClass
  # +true+ is not blank:
  #
  #   true.blank? # => false
  #
  def blank?
    false
  end
end

class Array
  # An array is blank if it's empty:
  #
  #   [].blank?      # => true
  #   [1,2,3].blank? # => false
  #
  alias_method :blank?, :empty?
end

class Hash
  # A hash is blank if it's empty:
  #
  #   {}.blank?                # => true
  #   {:key => 'value'}.blank? # => false
  #
  alias_method :blank?, :empty?
end

class String
  # A string is blank if it's empty or contains whitespaces only:
  #
  #   "".blank?                 # => true
  #   "   ".blank?              # => true
  #   "　".blank?               # => true
  #   " something here ".blank? # => false
  #
  def blank?
    self !~ /[^[:space:]]/
  end
end

class Numeric #:nodoc:
  # No number is blank:
  #
  #   1.blank? # => false
  #   0.blank? # => false
  #
  def blank?
    false
  end
end
