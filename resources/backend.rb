#
# Cookbook Name:: sensu-go
# Resource:: backend
#
# Copyright:: 2018 Sensu, Inc.
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

resource_name :sensu_backend

include SensuCookbook::Helpers
include SensuCookbook::SensuPackageProperties
include SensuCookbook::SensuCommonProperties

property :config, Hash, default: { "state-dir": '/var/lib/sensu/sensu-backend' }

action :install do
  packagecloud_repo new_resource.repo do
    type value_for_platform_family(
      %w(rhel fedora amazon) => 'rpm',
      'default' => 'deb'
    )
  end

  package 'sensu-go-backend' do
    if latest_version?(new_resource.version)
      action :upgrade
    else
      action :install
      version new_resource.version
    end
  end

  # render template at /etc/sensu/backend.yml
  file ::File.join(new_resource.config_home, 'backend.yml') do
    content(stringify_keys(new_resource.config))
  end

  service 'sensu-backend' do
    if node['platform'] == 'ubuntu' && node['platform_version'].to_f == 14.04
      provider Chef::Provider::Service::Init
      action :start
    else
      action [:enable, :start]
    end
  end
end

action :uninstall do
  service 'sensu-backend' do
    action [:disable, :stop]
  end

  package 'sensu-go-backend' do
    action :remove
  end
end
