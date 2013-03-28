#==============================================================================
# Copyright (C) 2012-2013 Stephen F Norledge & Alces Software Ltd.
#
# This file is part of Alces Storage.
#
# Alces Storage is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this software.  If not, see <http://www.gnu.org/licenses/>.
#
# Some rights reserved, see LICENSE.txt.
#==============================================================================
module Alces
  module Tools
    module DM
      # Provide sharding for datamapper models.
      #
      # Example of use:
      #
      #    module Foo
      #      module Sharding
      #        extend BaseSharding
      #        extend self
      #
      #        # Return a symbol which
      #        #   1) identifies the shard to use for the given user, and
      #        #   2) is unique across all modules using Alces::Tools::DM::Sharding.
      #        def shard_name(user)
      #          :"disk_quotas_#{user.tenant.id}"
      #        end
      #
      #        # Return a hash, with a single mandatory option, :adapter,
      #        # which is the name of the DataMapper adapter to use. All other
      #        # entries are options to be given to the adapter.
      #        def options(user)
      #          {
      #            adapter: 'disk_quotas',
      #            target: user.tenant,
      #            service: Alces.app.disk_quotas
      #          }
      #        end
      #      end
      #    end
      #
      # XXX Remove the requirement for shard_name to return a globally unique
      # name. Perhaps by prefixing it with the name of the "subclass".
      module Sharding
        remove_const(:ADAPTERS) if const_defined?(:ADAPTERS)
        ADAPTERS = {}

        extend self

        def shard(user, &block)
          shard_name = shard_name(user)
          unless ADAPTERS[shard_name]
            ADAPTERS[shard_name] = ::DataMapper.setup(shard_name, options(user))
          end

          ::DataMapper.repository(shard_name, &block)
        end
      end
    end
  end
end
