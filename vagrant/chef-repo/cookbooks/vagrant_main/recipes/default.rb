#
# Cookbook Name:: vagrant_main
# Recipe:: default
#

def network?
  node[:hagar_net] != 'false'
end

::APPS = node[:hagar_apps]
::GEMS = node[:hagar_gems]
::PASSENGER_MAX_INSTANCES_PER_APP = 2
::RAILS_2_VERSION = '2.3.9'
::RAILS_3_VERSION = '3.0.0'
::PASSENGER_VERSION = '2.2.15'
::HOME = '/home/vagrant'
::SHARED_FOLDER = '/vagrant'
::UNIVERSE = 'vagrant'
::MYSQL_PASSWORD = 'password'
::RVM_RUBY_VERSIONS = %w{ ruby-1.9.2-p0 ruby-1.8.7-p174 }
::DEFAULT_RUBY_VERSION = 'ruby-1.8.7-p174'

# steal a trick from mysql::client... run the apt-get update immediately
if network?
  a = execute 'update apt-get' do
    user 'root'
    command '/usr/bin/apt-get update'
    action :nothing
  end
  a.run_action :run
end

if network?
  package 'vim' # for derek
  package 'libreadline-dev' # for 1.9.2 irb ... http://rvm.beginrescueend.com/packages/readline/
  package 'g++' # for building passenger
  package 'libevent-dev'
  package "mysql-server"
  package "libmysqlclient-dev"
  package "sqlite3"
  package "libsqlite3-dev"
  package 'git-core' # for bundler when the source is git
  package 'libcurl4-openssl-dev' # for curb
  package 'libxml2-dev' # for libxml-ruby and nokogiri
  package 'libxslt1-dev' # for nokogiri
  package 'libonig-dev' # for onigurama
  package 'imagemagick' # for paperclip
  package 'libsasl2-dev' # for memcached
  package 'curl' # for data_miner and remote_table
  package 'unzip' # for remote_table
  # # package 'libsaxonb-java' # for data1
  package 'apache2' # apparently this wasn't installed by default
  package 'apache2-prefork-dev' # for passenger
  package 'libapr1-dev' # for passenger
  package 'libaprutil1-dev' # for passenger
end

if network?
  require_recipe "memcached" # old memcached
end
execute 'tell memcached to listen on all interfaces' do
  user 'root'
  command 'sed --expression="s/^-l/#-l/" --in-place="" /etc/memcached.conf'
end
execute 'restart memcached so that it picks up the conf change' do
  user 'root'
  command '/etc/init.d/memcached restart'
  ignore_failure true
end

execute "ensure mysql password is set" do
  user 'root'
  command "/usr/bin/mysql -u root -e \"UPDATE mysql.user SET password = PASSWORD('#{::MYSQL_PASSWORD}'); FLUSH PRIVILEGES\""
  not_if "/usr/bin/mysql -u root -p#{::MYSQL_PASSWORD} -e \"FLUSH PRIVILEGES\""
end

::APPS.each do |name|
  %w{ test development production }.each do |flavor|
    execute "make sure we have a #{name} #{flavor} database" do
      user 'vagrant'
      command "/usr/bin/mysql -u root -p#{::MYSQL_PASSWORD} -e 'CREATE DATABASE IF NOT EXISTS #{name}_#{flavor}'"
    end
  end
end

execute 'define /etc/universe' do
  user 'root'
  command "/bin/echo \"#{::UNIVERSE}\" > /etc/universe"
end

cookbook_file "/usr/bin/hostsync" do
  source "hostsync"
  mode '755'
end

cookbook_file '/usr/bin/gem' do
  owner 'root'
  source 'gem.rb'
  mode '755'
end

# sabshere 9/30/10 TODO for app1
# gem install for apps that don't yet have Gemfiles
# ::APPS.each do |name|
#   proto_rails_root = File.join ::SHARED_FOLDER, 'apps_enabled', name
#   next if File.readable?(File.join(proto_rails_root, 'Gemfile'))
#   IO.readlines(File.join(proto_rails_root, 'config', 'environment.rb')).grep(/config\.gem/).each do |line|
#     if /config\.gem ['"](.*?)['"],.*\:version => ['"][^0-9]{0,2}(.*?)['"]/.match line
#       gem_name = $1
#       gem_version = $2
#     elsif /config\.gem ['"](.*?)['"]/.match line
#       gem_name = $1
#       gem_version = 'latest'
#     end
#     gem_versions[gem_name] ||= Array.new
#     gem_versions[gem_name] << gem_version
#     gem_beneficiaries[gem_name] ||= Array.new
#     gem_beneficiaries[gem_name] << name
#   end
# end

if network?
  gem_versions = Hash.new
  gem_versions['rvm'] = ['latest']
  gem_versions.each do |name, versions|
    versions.uniq.each do |x|
      execute "install gem #{name} version #{x}" do
        user 'root'
        command "gem install #{name} #{" --version \"#{x}\"" unless x == 'latest'}"
        not_if "gem list --installed #{name}#{" --version \"#{x}\"" unless x == 'latest'}"
      end
    
      if x == 'latest'
        execute "checking latest version of #{name}" do
          user 'root'
          command "gem update #{name}"
        end
      end
    end
  end
end

if network?
  remote_file "/usr/bin/rvm-install-system-wide" do
    owner 'root'
    source "http://bit.ly/rvm-install-system-wide"
    mode '755'
  end

  execute 'install rvm system-wide' do
    user 'root'
    command 'rvm-install-system-wide'
    ignore_failure true
    not_if "grep rvm /etc/group"
  end

  ::RVM_RUBY_VERSIONS.each do |v|
    execute "install #{v}" do
      user 'root'
      command "rvm install #{v}" # -C --with-readline-dir=/usr
      not_if "rvm list | grep #{v}"
    end
  end
  
  # in case rubyforge goes down
  # %w{ http://rubyforge.org/frs/download.php/69365 http://rubyforge.org/frs/download.php/70696 }.each do |bad_url|
  #   execute "don't use bad url #{bad_url}" do
  #     user 'root'
  #     command "sed --expression=\"s/#{bad_url.gsub('/', '\/')}/#{'http://github.com/seamusabshere/rvm/raw/master/contrib'.gsub('/', '\/')}/\" --in-place=\"\" /usr/local/rvm/config/db"
  #   end
  # end
end

execute 'add vagrant to rvm group' do
  user 'root'
  command 'usermod --append --groups rvm vagrant'
  ignore_failure true
end

# execute "set #{::DEFAULT_RUBY_VERSION} as the default ruby" do
#   user 'root'
#   command "rvm --default #{::DEFAULT_RUBY_VERSION}"
#   ignore_failure true
# end

cookbook_file '/usr/bin/ruby_version.rb' do
  owner 'root'
  source 'ruby_version.rb'
  mode '755'
end

cookbook_file '/usr/bin/add_rvm_to_bashrc.sh' do
  owner 'root'
  source 'add_rvm_to_bashrc.sh'
  mode '755'
end

{
  'vagrant' => '/home/vagrant',
  'root' => '/root'
}.each do |username, homedir|  
  execute "add rvm stuff to .bashrc for #{username}" do
    user username
    cwd homedir
    command "add_rvm_to_bashrc.sh"
  end
end

gem_installs = Array.new
gem_installs.push ['ruby-debug', /1.8.7/, 'latest']
gem_installs.push ['fastercsv', /1.8.7/, 'latest'] # long story
gem_installs.push ['bundler', 'all', 'latest']
gem_installs.push ['passenger', 'all', ::PASSENGER_VERSION]
gem_installs.push ['unicorn', 'all', 'latest']
gem_installs.push ['mysql', 'all', 'latest']
gem_installs.push ['sqlite3-ruby', 'all', 'latest']
gem_installs.push ['rails', 'all', ::RAILS_3_VERSION]
gem_installs.push ['jeweler', 'all', 'latest']
gem_installs.push ['shoulda', 'all', 'latest']
gem_installs.push ['mocha', 'all', 'latest']
gem_installs.push ['taps', 'all', 'latest']
gem_installs.push ['chef', 'all', 'latest']

execute 'make sure vagrant owns /home/vagrant/.gem' do
  user 'root'
  command 'chown -R vagrant /home/vagrant/.gem'
  ignore_failure true
end

if network?
  ::RVM_RUBY_VERSIONS.each do |v|
    gem_installs.each do |name, ruby_version, gem_version|
      if ruby_version == 'all' or ruby_version =~ v
        execute "install gem #{name} version #{gem_version} in ruby version #{v}" do
          user 'vagrant'
          command "rvm #{v} gem install #{name} --no-rdoc --no-ri #{" --version \"#{gem_version}\"" unless gem_version == 'latest'}"
          not_if "rvm #{v} gem list --installed #{name}#{" --version \"#{gem_version}\"" unless gem_version == 'latest'}"
          ignore_failure true
        end
        if gem_version == 'latest'
          execute "checking latest version of #{name} in ruby version #{v}" do
            user 'vagrant'
            command "rvm #{v} gem update #{name} --no-rdoc --no-ri"
            ignore_failure true
          end
        end
      end
    end
  end
end

::RVM_RUBY_VERSIONS.each do |ruby_version|
  execute "prepare passenger module for apache2 in #{ruby_version}" do
    user 'vagrant'
    cwd "/usr/local/rvm/gems/#{ruby_version}/gems/passenger-#{::PASSENGER_VERSION}"
    command "rvm #{ruby_version} rake apache2"
    not_if "[ -f /usr/local/rvm/gems/#{ruby_version}/gems/passenger-#{::PASSENGER_VERSION}/ext/apache2/mod_passenger.so ]"
    ignore_failure true
  end
end

template "/etc/apache2/mods-available/passenger.conf" do
  cookbook "vagrant_main"
  source "passenger.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :passenger_version => ::PASSENGER_VERSION,
    :rubies => ::RVM_RUBY_VERSIONS,
    :default_ruby_version => ::DEFAULT_RUBY_VERSION,
    :passenger_max_instances_per_app => ::PASSENGER_MAX_INSTANCES_PER_APP
  )
end

template "/etc/apache2/mods-available/passenger.load" do
  cookbook "vagrant_main"
  source "passenger.load.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :passenger_version => ::PASSENGER_VERSION,
    :rubies => ::RVM_RUBY_VERSIONS,
    :default_ruby_version => ::DEFAULT_RUBY_VERSION
  )
end

execute "enable passenger.load" do
  user 'root'
  command %{
    unlink /etc/apache2/mods-enabled/passenger.load;
    ln -s /etc/apache2/mods-available/passenger.load /etc/apache2/mods-enabled/passenger.load;
    unlink /etc/apache2/mods-enabled/passenger.conf;
    ln -s /etc/apache2/mods-available/passenger.conf /etc/apache2/mods-enabled/passenger.conf
  }
  ignore_failure true
end

::GEMS.each do |name|
  proto_gem_root = File.join ::SHARED_FOLDER, 'gems_enabled', name
  gem_root = File.join ::HOME, name
  
  execute "clear the way for #{gem_root}" do
    user 'vagrant'
    command "unlink #{gem_root}; rm -rf #{gem_root}"
    ignore_failure true
  end
  
  execute "symbolic link #{proto_gem_root} from read-only shared dir" do
    user 'vagrant'
    command "/bin/ln -s #{proto_gem_root} #{gem_root}"
  end
end

execute "clear out old enabled sites" do
  user 'root'
  command "/usr/bin/find /etc/apache2/sites-enabled -maxdepth 1 -type l | /usr/bin/xargs -n 1 /usr/bin/unlink"
  ignore_failure true
end

# note: currently ignoring dot-files
::IGNORED_PATHS = %w{ .bundle .git }

::APPS.each do |name|
  proto_rails_root = File.join ::SHARED_FOLDER, 'apps_enabled', name
  rails_root = File.join ::HOME, name
  ruby_version = File.exist?(File.join(rails_root, 'RUBY_VERSION')) ? IO.read(File.join(rails_root, 'RUBY_VERSION')).chomp : ::DEFAULT_RUBY_VERSION
    
  execute "create #{rails_root}" do
    user 'vagrant'
    command "mkdir -p #{rails_root}"
  end

  execute "clear out old symlinks from #{rails_root}" do
    user 'vagrant'
    command "/usr/bin/find #{rails_root} -maxdepth 1 -type l | /usr/bin/xargs -n 1 /usr/bin/unlink"
    ignore_failure true
  end
  
  execute "clear out tmp and log from #{rails_root}" do
    user 'root'
    command "mkdir -p #{rails_root}/tmp; mkdir -p #{rails_root}/log; rm -rf #{rails_root}/tmp/* #{rails_root}/log/*; chown vagrant #{rails_root}/log; chown vagrant #{rails_root}/tmp"
    ignore_failure true
  end

  Dir[File.join(proto_rails_root, '*')].delete_if { |linkable_path| (::IGNORED_PATHS).include?(File.basename(linkable_path)) }.each do |linkable_path|
    execute "symbolic link #{linkable_path} from read-only shared dir" do
      user 'vagrant'
      command "/usr/bin/hostsync #{linkable_path}"
      # command "/bin/ln -s #{linkable_path} #{File.join(rails_root, linkable_path.sub(proto_rails_root, ''))}"
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
    command "/bin/ln -s /etc/apache2/sites-available/#{name}.conf /etc/apache2/sites-enabled/#{name}.conf"
    ignore_failure true
  end
  
  if File.exist?(File.join(rails_root, 'Gemfile'))
    # sabshere 10/4/10 this errored out a lot
    # execute "make sure user can write to bundle for #{name}" do
    #   user 'root'
    #   command "chown -R vagrant /home/vagrant/.bundle; chown -R vagrant #{rails_root}/.bundle"
    #   ignore_failure true
    # end
    
    if network?
      execute "run bundler install for #{name}" do
        user 'vagrant'
        command "rvm #{ruby_version} exec bundle install"
        cwd rails_root
        ignore_failure true
      end
    end
  end
end

if ::APPS.include? 'wlpf1'
  execute "establish wlpf1 as the default virtualhost" do
    user 'root'
    command "/usr/bin/unlink /etc/apache2/sites-enabled/000-default; /usr/bin/unlink /etc/apache2/sites-enabled/wlpf1.conf; /usr/bin/unlink /etc/apache2/sites-enabled/000-wlpf1.conf; /bin/ln -s /etc/apache2/sites-available/wlpf1.conf /etc/apache2/sites-enabled/000-wlpf1.conf; true"
  end
end

template "/home/vagrant/.bash_aliases" do
  cookbook "vagrant_main"
  source ".bash_aliases.erb"
  owner "vagrant"
  group "vagrant"
  mode 0644
  variables :repos => GEMS+APPS
end

execute "make sure git autocrlf is set" do
  user 'vagrant'
  command 'git config --global core.autocrlf input'
end

execute 'make sure mysqld uses innodb' do
  user 'root'
  # command 'string_replacer /etc/mysql/my.cnf default-storage-engine=INNODB "make sure mysqld uses innodb" "[mysqld]"'
  command %{sed '/[mysqld]/ a default-storage-engine=INNODB' --in-place="" /etc/mysql/my.cnf}
  not_if %{grep 'default-storage-engine=INNODB' /etc/mysql/my.cnf}
end

execute 'make sure sendfile is off' do
  user 'root'
  # command 'string_replacer /etc/apache2/apache2.conf "EnableSendfile Off" "make sure sendfile is off" "HostnameLookups Off"'
  command %{sed '/HostnameLookups Off/ a EnableSendfile Off' --in-place="" /etc/apache2/apache2.conf}
  not_if %{grep 'EnableSendfile Off' /etc/apache2/apache2.conf}
end

execute "restart apache" do
  user 'root'
  command 'service apache2 restart'
end
