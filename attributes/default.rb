#
# Cookbook Name:: nfs
# Attributes:: default
#
# Copyright 2011, Eric G. Wolfe
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Allowing Version 2, 3 and 4 of NFS to be enabled or disabled.
# Default behavior, defer to protocol level(s) supported by kernel.
default['nfs']['v2'] = nil
default['nfs']['v3'] = nil
default['nfs']['v4'] = nil

# Default options are taken from the Debian guide on static NFS ports
default['nfs']['port']['statd'] = 32_765
default['nfs']['port']['statd_out'] = 32_766
default['nfs']['port']['mountd'] = 32_767
default['nfs']['port']['lockd'] = 32_768

# Number of rpc.nfsd threads to start (default 8)
default['nfs']['threads'] = 8

# Default options are based on RHEL5, as the attribute names were
# adopted from this platform.
default['nfs']['packages'] = %w(nfs-utils portmap)
default['nfs']['service']['portmap'] = 'portmap'
default['nfs']['service']['lock'] = 'nfslock'
default['nfs']['service']['server'] = 'nfs'
default['nfs']['service_provider']['lock'] = Chef::Platform.find_provider_for_node node, :service
default['nfs']['service_provider']['portmap'] = Chef::Platform.find_provider_for_node node, :service
default['nfs']['service_provider']['server'] = Chef::Platform.find_provider_for_node node, :service
default['nfs']['config']['client_templates'] = %w(/etc/sysconfig/nfs)
default['nfs']['config']['server_template'] = '/etc/sysconfig/nfs'

case node['platform_family']

when 'rhel'
  # RHEL6 edge case package set and portmap name
  if node['platform_version'].to_i >= 6 || platform?('amazon')
    default['nfs']['packages'] = %w(nfs-utils rpcbind)
    default['nfs']['service']['portmap'] = 'rpcbind'
  end

when 'freebsd'
  # Packages are installed by default
  default['nfs']['packages'] = []
  default['nfs']['config']['server_template'] = '/etc/rc.conf.d/nfsd'
  default['nfs']['config']['client_templates'] = %w(/etc/rc.conf.d/mountd)
  default['nfs']['service']['portmap'] = 'rpcbind'
  default['nfs']['service']['lock'] = 'lockd'
  default['nfs']['service']['server'] = 'nfsd'
  default['nfs']['threads'] = 24
  default['nfs']['mountd_flags'] = '-r'
  if node['nfs']['threads'] >= 0
    default['nfs']['server_flags'] = "-u -t -n #{node['nfs']['threads']}"
  else
    default['nfs']['server_flags'] = '-u -t'
  end

when 'suse'
  default['nfs']['packages'] = %w(nfs-client nfs-kernel-server rpcbind)
  default['nfs']['service']['portmap'] = 'rpcbind'
  default['nfs']['service']['lock'] = 'nfsserver'
  default['nfs']['service']['server'] = 'nfsserver'
  default['nfs']['config']['client_templates'] = %w(/etc/sysconfig/nfs)

when 'debian'
  default['nfs']['packages'] = %w(nfs-common portmap)
  default['nfs']['service']['portmap'] = 'portmap'
  default['nfs']['service']['lock'] = 'statd'
  default['nfs']['service']['server'] = 'nfs-kernel-server'
  default['nfs']['config']['client_templates'] = %w(/etc/default/nfs-common /etc/modprobe.d/lockd.conf)
  default['nfs']['config']['server_template'] = '/etc/default/nfs-kernel-server'

  case node['platform']

  when 'ubuntu'

    # Ubuntu 11.04 edge case package set and portmap name
    if node['platform_version'].to_f == 11.04
      default['nfs']['service']['portmap'] = 'rpcbind'
      default['nfs']['packages'] = %w(nfs-common rpcbind)
    # Ubuntu 11.10 edge case package set and portmap name
    elsif node['platform_version'].to_f >= 11.10
      default['nfs']['service']['portmap'] = 'rpcbind-boot'
      default['nfs']['packages'] = %w(nfs-common rpcbind)
    end

    # Ubuntu 13.10+ service provider is Upstart for portmap and lock
    if node['platform_version'].to_f >= 13.10
      default['nfs']['service_provider']['portmap'] = Chef::Provider::Service::Upstart
      default['nfs']['service_provider']['lock'] = Chef::Provider::Service::Upstart
    end

  when 'debian'

    # Debian 6.0+
    if node['platform_version'].to_i >= 6
      default['nfs']['service']['lock'] = 'nfs-common'
    end

    # Debian 7.0+ (wheezy)
    if node['platform_version'].to_i >= 7
      default['nfs']['service']['lock'] = 'nfs-common'
      default['nfs']['service']['portmap'] = 'rpcbind'
      default['nfs']['packages'] = %w(nfs-common rpcbind)
    end

  end

end
