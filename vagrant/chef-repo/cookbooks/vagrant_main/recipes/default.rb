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

::APPS = node[:hagar_apps]
::GEMS = node[:hagar_gems]
::PASSENGER_MAX_INSTANCES_PER_APP = 2
::RAILS_2_VERSION = '2.3.5'
::RAILS_3_VERSION = '3.0.0.beta3'
::PASSENGER_VERSION = '2.2.11'
::HOME = '/home/vagrant'
::SHARED_FOLDER = '/vagrant'
::UNIVERSE = 'vagrant'
::MYSQL_PASSWORD = 'password'

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

remote_file "/usr/bin/rep.rb" do
  source "rep.rb"
  mode '755'
end

package 'libevent-dev'
require_recipe "memcached" # old memcached

package "mysql-server"
package "libmysqlclient-dev"

execute "ensure mysql password is set" do
  user 'root'
  command "/usr/bin/mysql -u root -e \"UPDATE mysql.user SET password = PASSWORD('#{::MYSQL_PASSWORD}'); FLUSH PRIVILEGES\""
  not_if "/usr/bin/mysql -u root -p#{::MYSQL_PASSWORD} -e \"FLUSH PRIVILEGES\""
end

package "sqlite3"
package "libsqlite3-dev"

::APPS.each do |name|
  %w{ test development production }.each do |flavor|
    execute "make sure we have a #{name} #{flavor} database" do
      user 'vagrant'
      command "/usr/bin/mysql -u root -p#{::MYSQL_PASSWORD} -e 'CREATE DATABASE IF NOT EXISTS #{name}_#{flavor}'"
    end
  end
end  

package 'git-core' # for bundler when the source is git
package 'libcurl4-openssl-dev' # for curb
package 'libxml2-dev' # for libxml-ruby and nokogiri
package 'libxslt1-dev' # for nokogiri
package 'libonig-dev' # for onigurama
package 'imagemagick' # for paperclip
package 'libsasl2-dev' # for memcached
package 'curl' # for data_miner and remote_table
package 'unzip' # for remote_table
package 'libsaxonb-java' # for data1
package 'apache2' # apparently this wasn't installed by default
package 'apache2-prefork-dev' # for passenger
package 'libapr1-dev' # for passenger
package 'libaprutil1-dev' # for passenger

gem_versions = Hash.new
gem_beneficiaries = Hash.new
::APPS.each do |name|
  proto_rails_root = File.join ::SHARED_FOLDER, 'apps_enabled', name
  next if File.readable?(File.join(proto_rails_root, 'Gemfile'))
  IO.readlines(File.join(proto_rails_root, 'config', 'environment.rb')).grep(/config\.gem/).each do |line|
    if /config\.gem ['"](.*?)['"],.*\:version => ['"][^0-9]{0,2}(.*?)['"]/.match line
      gem_name = $1
      gem_version = $2
    elsif /config\.gem ['"](.*?)['"]/.match line
      gem_name = $1
      gem_version = 'latest'
    end
    gem_versions[gem_name] ||= Array.new
    gem_versions[gem_name] << gem_version
    gem_beneficiaries[gem_name] ||= Array.new
    gem_beneficiaries[gem_name] << name
  end
end

#common gems
gem_versions['passenger'] = [::PASSENGER_VERSION]
gem_versions['bundler'] = ['0.9.25']
gem_versions['mysql'] = ['2.8.1']
gem_versions['sqlite3-ruby'] = ['1.2.5']
gem_versions['rails'] = [::RAILS_2_VERSION]
gem_versions['ruby-debug'] = ['0.10.3']
gem_versions['jeweler'] = ['1.4.0']
gem_versions['shoulda'] = ['2.10.3']
gem_versions['mocha'] = ['0.9.8']

gem_versions.each do |name, versions|
  versions.uniq.each do |x|
    execute "install gem #{name} version #{x} on behalf of #{gem_beneficiaries[name].to_a.join(',')}" do
      user 'root'
      command "gem install #{name} --source=http://rubygems.org --source=http://gems.github.com#{" --version #{x}" unless x == 'latest'}"
      not_if "gem list --installed #{name}#{" --version #{x}" unless x == 'latest'}"
    end
    
    if x == 'latest'
      execute "checking latest version of #{name} on behalf of #{gem_beneficiaries[name].to_a.join(',')}" do
        user 'root'
        command "gem update #{name}"
      end
    end
  end
end

execute 'install rails 3' do
  user 'root'
  command 'gem install rails --pre --no-rdoc --no-ri'
  not_if "gem list --installed rails --version #{::RAILS_3_VERSION}"
end

execute 'install passenger module for apache2' do
  user 'root'
  cwd "/usr/lib/ruby/gems/1.8/gems/passenger-#{::PASSENGER_VERSION}"
  command 'rake apache2'
  not_if "[ -f /usr/lib/ruby/gems/1.8/gems/passenger-#{::PASSENGER_VERSION}/ext/apache2/mod_passenger.so ]"
end

template "/etc/apache2/mods-available/passenger.conf" do
  cookbook "vagrant_main"
  source "passenger.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :passenger_max_instances_per_app => ::PASSENGER_MAX_INSTANCES_PER_APP,
    :passenger_version => ::PASSENGER_VERSION
  )
end

template "/etc/apache2/mods-available/passenger.load" do
  cookbook "vagrant_main"
  source "passenger.load.erb"
  owner "root"
  group "root"
  mode 0644
  variables :passenger_version => ::PASSENGER_VERSION
end

execute "enable passenger.load" do
  user 'root'
  command %{
    unlink /etc/apache2/mods-enabled/passenger.load;
    ln -s /etc/apache2/mods-available/passenger.load /etc/apache2/mods-enabled/passenger.load;
    unlink /etc/apache2/mods-enabled/passenger.conf;
    ln -s /etc/apache2/mods-available/passenger.conf /etc/apache2/mods-enabled/passenger.conf;
    /bin/true
  }
end

# note: currently ignoring dot-files
::IGNORED_PATHS = %w{ .bundle .git .vagrant vagrant Vagrantfile vagrant_main }

execute "clear out old enabled sites" do
  user 'root'
  command "/usr/bin/find /etc/apache2/sites-enabled -maxdepth 1 -type l | /usr/bin/xargs -n 1 /usr/bin/unlink; /bin/true"
  # note that I am ignoring errors with /bin/true
end

::GEMS.each do |name|
  proto_gem_root = File.join ::SHARED_FOLDER, 'gems_enabled', name
  gem_root = File.join ::HOME, name
  
  execute "clear the way for #{gem_root}" do
    user 'vagrant'
    command "unlink #{gem_root}; rm -rf #{gem_root}; /bin/true"
    # ignoring failure
  end
  
  execute "symbolic link #{proto_gem_root} from read-only shared dir" do
    user 'vagrant'
    command "/bin/ln -s #{proto_gem_root} #{gem_root}"
  end
end

::APPS.each do |name|
  proto_rails_root = File.join ::SHARED_FOLDER, 'apps_enabled', name
  rails_root = File.join ::HOME, name
    
  execute "create #{rails_root}" do
    user 'vagrant'
    command "mkdir -p #{rails_root}"
  end

  execute "clear out old symlinks from #{rails_root}" do
    user 'vagrant'
    command "/usr/bin/find #{rails_root} -maxdepth 1 -type l | /usr/bin/xargs -n 1 /usr/bin/unlink; /bin/true"
    # note that I am ignoring errors with /bin/true
  end
  
  execute "clear out any inadvertently created real dirs from #{rails_root}" do
    user 'root'
    command "rm -rf #{rails_root}/tmp #{rails_root}/log; /bin/true"
    #ignoring failure
  end

  Dir[File.join(proto_rails_root, '*')].delete_if { |linkable_path| (::IGNORED_PATHS).include?(File.basename(linkable_path)) }.each do |linkable_path|
    execute "symbolic link #{linkable_path} from read-only shared dir" do
      user 'vagrant'
      command "/bin/ln -s #{linkable_path} #{File.join(rails_root, linkable_path.sub(proto_rails_root, ''))}"
    end
  end

  template "/etc/apache2/sites-available/#{name}.conf" do
    cookbook "vagrant_main"
    source "web_app.conf.erb"
    owner "root"
    group "root"
    mode 0644
    variables(
      :server_name => "#{name}.vagrant.local",
      :docroot => "#{rails_root}/public",
      :rack_env => 'development',
      :rails_env => 'development'
    )
  end
  
  execute "enable site for #{name}" do
    user 'root'
    command "/bin/ln -s /etc/apache2/sites-available/#{name}.conf /etc/apache2/sites-enabled/#{name}.conf; /bin/true"
    # ignoring fail
  end
  
  if File.readable?(File.join(rails_root, 'Gemfile'))
    execute "make sure user can write to bundle for #{name}" do
      user 'root'
      command "chown -R vagrant /home/vagrant/.bundle; chown -R vagrant #{rails_root}/.bundle;"
    end
    
    execute "run bundler install for #{name}" do
      user 'vagrant'
      command 'bundle install'
      cwd rails_root
    end
  end
end

if ::APPS.include? 'wlpf1'
  execute "establish wlpf1 as the default virtualhost" do
    user 'root'
    command "/usr/bin/unlink /etc/apache2/sites-enabled/000-default; /usr/bin/unlink /etc/apache2/sites-enabled/wlpf1.conf; /usr/bin/unlink /etc/apache2/sites-enabled/000-wlpf1.conf; /bin/ln -s /etc/apache2/sites-available/wlpf1.conf /etc/apache2/sites-enabled/000-wlpf1.conf; true"
  end
end

execute "restart apache" do
  user 'root'
  command 'service apache2 restart'
end

execute "make sure git autocrlf is set" do
  user 'vagrant'
  command 'git config --global core.autocrlf input'
end

execute 'make sure mysqld uses innodb' do
  user 'root'
  command '/usr/bin/rep.rb /etc/mysql/my.cnf default-storage-engine=INNODB "make sure mysqld uses innodb" "[mysqld]"'
end
