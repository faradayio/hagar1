#
# Cookbook Name:: vagrant_main
# Recipe:: default
#
# Copyright 2010, Example Com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'pp'

::APPS = %w{ kayak1 data1 wlpf1 }
::PASSENGER_MAX_INSTANCES_PER_APP = 2
::RAILS_VERSION = '2.3.5'
::HOME = '/home/vagrant'
::SHARED_FOLDER = '/vagrant'
::PATH = '/opt/ruby-enterprise/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games'
::UNIVERSE = 'vagrant'

# steal a trick from mysql::client... run the apt-get update immediately
a = execute 'update apt-get' do
  user 'root'
  command '/usr/bin/apt-get update'
  action :nothing
end
a.run_action :run

execute 'define /etc/universe' do
  user 'root'
  command "/bin/echo \"#{::UNIVERSE}\" > /etc/universe"
end

execute "manually overwrite path" do
  user 'root'
  command "PATH=\"#{::PATH}\"; export PATH; /bin/echo \"PATH=$PATH\" > /etc/environment"
end

package 'curl'

# start memcached
package 'libevent-dev'
require_recipe "memcached" # old memcached
execute "manually upgrade memcached" do
  user 'root'
  command %{
    cd;
    curl -O http://memcached.googlecode.com/files/memcached-1.4.5.tar.gz;
    tar -xzf memcached-1.4.5.tar.gz;
    cd memcached-1.4.5;
    /home/vagrant/configure;
    make;
    make install clean;
    mv /usr/bin/memcached /usr/bin/memcached-old;
    ln -s /usr/local/bin/memcached /usr/bin/memcached;
  }
  not_if 'memcached -h | grep 1.4.5'
end
execute "bound memcached" do
  user 'root'
  command '/etc/init.d/memcached restart'
end
# end memcached

include_recipe "ruby_enterprise"

include_recipe "mysql::server"

package "sqlite3"
package "libsqlite3-dev"

::APPS.each do |name|
  %w{ test development production }.each do |flavor|
    execute "make sure we have a #{name} #{flavor} database" do
      user 'vagrant'
      command "/usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} -e 'CREATE DATABASE IF NOT EXISTS #{name}_#{flavor}'"
    end
  end
end  

package 'libcurl4-openssl-dev' # for curb
package 'libxml2-dev' # for libxml-ruby and nokogiri
package 'libxslt1-dev' # for nokogiri
package 'libonig-dev' # for onigurama
package 'imagemagick' # for paperclip
package 'libsasl2-dev' # for memcached
package 'curl' # for data_miner and remote_table
package 'unzip' # for remote_table

execute "update gem system" do
  user 'root'
  command '/opt/ruby-enterprise/bin/gem update --system'
end

gem_versions = Hash.new
::APPS.each do |name|
  IO.readlines("#{::SHARED_FOLDER}/#{name}/config/environment.rb").grep(/config\.gem/).each do |line|
    if /config\.gem ['"](.*?)['"],.*\:version => ['"](.*?)['"]/.match line
      gem_versions[$1] ||= Array.new
      gem_versions[$1] << $2
    elsif /config\.gem ['"](.*?)['"]/.match line
      gem_versions[$1] ||= Array.new
      gem_versions[$1] << 'latest'
    else
      raise "Can't read #{line}"
    end
  end
end

#common gems
gem_versions['mysql'] = ['latest']
gem_versions['sqlite3-ruby'] = ['latest']
gem_versions['rails'] = [::RAILS_VERSION]

gem_versions.each do |name, versions|
  versions.uniq.each do |x|
    ree_gem name do
      version x unless x == 'latest'
      source "http://rubygems.org"
      not_if "/opt/ruby-enterprise/bin/gem list --installed #{name}#{" --version #{x}" unless x == 'latest'}"
    end
    
    if x == 'latest'
      execute "trying to update #{name}" do
        user 'root'
        command "/opt/ruby-enterprise/bin/gem update #{name}"
      end
    end
  end
end

include_recipe 'passenger_enterprise::apache2'

apache_site 'default', :disable => true

# re-install passenger conf, this time with a smaller pool size
template "#{node[:apache][:dir]}/mods-available/passenger.conf" do
  cookbook "vagrant_main"
  source "passenger.conf.erb"
  owner "root"
  group "root"
  mode 0755
  variables(
    :passenger_root => node[:passenger_enterprise][:root_path],
    :passenger_ruby => node[:ruby_enterprise][:ruby_bin],
    :passenger_max_pool_size => ::APPS.length * ::PASSENGER_MAX_INSTANCES_PER_APP,
    :passenger_max_instances_per_app => ::PASSENGER_MAX_INSTANCES_PER_APP
  )
end

::UNSHARED_PATHS = %w{ tmp log }
# note: currently ignoring dot-files
::IGNORED_PATHS = %w{ .bundle .git .vagrant vagrant Vagrantfile vagrant_main }

::APPS.each do |name|
  proto_rails_root = File.join ::SHARED_FOLDER, name
  rails_root = File.join ::HOME, name
  
  ::UNSHARED_PATHS.each do |unshared_path|
    execute "create unshared #{unshared_path} on the virtualbox" do
      user 'vagrant'
      command "mkdir -p #{File.join rails_root, unshared_path}"
    end
  end

  execute "clear out old symlinks" do
    user 'vagrant'
    command "/usr/bin/find #{rails_root} -maxdepth 1 -type l | /usr/bin/xargs -n 1 /usr/bin/unlink; /bin/true"
    # note that I am ignoring errors with /bin/true
  end

  Dir[File.join(proto_rails_root, '*')].delete_if { |linkable_path| (::UNSHARED_PATHS + ::IGNORED_PATHS).include?(File.basename(linkable_path)) }.each do |linkable_path|
    execute "symbolic link #{linkable_path} from read-only shared dir" do
      user 'vagrant'
      command "/bin/ln -s #{linkable_path} #{File.join(rails_root, linkable_path.sub(proto_rails_root, ''))}"
    end
  end

  web_app name do
    docroot "#{rails_root}/public"
    server_name "#{name}.vagrant.local"
    rails_env 'development'
    rack_env 'development'
    cookbook 'vagrant_main'
  end
end

execute "establish wlpf1 as the default virtualhost" do
  user 'root'
  command "/usr/bin/unlink /etc/apache2/sites-enabled/000-default; /usr/bin/unlink /etc/apache2/sites-enabled/wlpf1.conf; /usr/bin/unlink /etc/apache2/sites-enabled/000-wlpf1.conf; /bin/ln -s /etc/apache2/sites-available/wlpf1.conf /etc/apache2/sites-enabled/000-wlpf1.conf; true"
end
