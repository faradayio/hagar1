require 'openssl'

pw = String.new

while pw.length < 20
  pw << OpenSSL::Random.random_bytes(1).gsub(/\W/, '')
end

# Where the various parts of tomcat6 are
case platform
when "centos"
  set[:tomcat6][:start]           = "/etc/init.d/tomcat6 start"
  set[:tomcat6][:stop]            = "/etc/init.d/tomcat6 stop"
  set[:tomcat6][:restart]         = "/etc/init.d/tomcat6 restart"
  set[:tomcat6][:home]            = "/usr/share/tomcat6" #don't use trailing slash. it breaks init script
  set[:tomcat6][:dir]             = "/etc/tomcat6/"
  set[:tomcat6][:conf]            = "/etc/tomcat6"
  set[:tomcat6][:temp]            = "/var/tmp/tomcat6"
  set[:tomcat6][:logs]            = "/var/log/tomcat6"
  set[:tomcat6][:webapp_base_dir] = "/srv/tomcat6/"
  set[:tomcat6][:webapps]         = File.join(tomcat6[:webapp_base_dir],"webapps")
  set[:tomcat6][:user]            = "tomcat"
  set[:tomcat6][:manager_dir]     = File.join(tomcat6[:home],"webapps/manager")
  set[:tomcat6][:port]            = 8080
  set[:tomcat6][:ssl_port]        = 8433
else
  set[:tomcat6][:start]           = "/etc/init.d/tomcat6 start"
  set[:tomcat6][:stop]            = "/etc/init.d/tomcat6 stop"
  set[:tomcat6][:restart]         = "/etc/init.d/tomcat6 restart"
  set[:tomcat6][:home]            = "/usr/share/tomcat6" #don't use trailing slash. it breaks init script
  set[:tomcat6][:dir]             = "/etc/tomcat6"
  set[:tomcat6][:conf]            = "/etc/tomcat6"
  set[:tomcat6][:temp]            = "/var/tmp/tomcat6"
  set[:tomcat6][:logs]            = "/var/log/tomcat6"
  set[:tomcat6][:webapp_base_dir] = "/srv/tomcat6/"
  set[:tomcat6][:webapps]         = File.join(tomcat6[:webapp_base_dir],"webapps")
  set[:tomcat6][:user]            = "tomcat"
  set[:tomcat6][:manager_dir]     = "/usr/share/tomcat6/webapps/manager"
  set[:tomcat6][:port]            = 8080
  set[:tomcat6][:ssl_port]        = 8433
end

set_unless[:tomcat6][:version]          = "6.0.18"
set_unless[:tomcat6][:with_native]      = false
# sabshere 9/28/10
# vagrant@vagrantup:~$ cd /tmp/vagrant-chef && sudo -E chef-solo -c solo.rb -j dna.json
# [Tue, 28 Sep 2010 09:11:33 -0700] INFO: Setting the run_list to [] from JSON
# [Tue, 28 Sep 2010 09:11:33 -0700] INFO: Starting Chef Run (Version 0.9.8)
# [Tue, 28 Sep 2010 09:11:37 -0700] WARN: Missing gem 'mysql'
# [Tue, 28 Sep 2010 09:11:37 -0700] WARN: Missing gem 'right_aws'
# [Tue, 28 Sep 2010 09:11:37 -0700] ERROR: Running exception handlers
# [Tue, 28 Sep 2010 09:11:37 -0700] ERROR: Exception handlers complete
# [Tue, 28 Sep 2010 09:11:37 -0700] ERROR: Re-raising exception: NoMethodError - undefined method `[]' for nil:NilClass
# /tmp/vagrant-chef/cookbooks-0/tomcat6/attributes/default.rb:45:in `from_file'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/node.rb:531:in `load_attributes'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/node.rb:529:in `each'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/node.rb:529:in `load_attributes'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/node.rb:528:in `each'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/node.rb:528:in `load_attributes'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/run_context.rb:74:in `load'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/run_context.rb:55:in `initialize'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/client.rb:84:in `new'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/client.rb:84:in `run'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/application/solo.rb:191:in `run_application'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/application/solo.rb:181:in `loop'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/application/solo.rb:181:in `run_application'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/application.rb:62:in `run'
#   /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/chef-solo:25
#   /usr/bin/chef-solo:19:in `load'
#   /usr/bin/chef-solo:19
# /tmp/vagrant-chef/cookbooks-0/tomcat6/attributes/default.rb:45:in `from_file': undefined method `[]' for nil:NilClass (NoMethodError)
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/node.rb:531:in `load_attributes'
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/node.rb:529:in `each'
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/node.rb:529:in `load_attributes'
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/node.rb:528:in `each'
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/node.rb:528:in `load_attributes'
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/run_context.rb:74:in `load'
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/run_context.rb:55:in `initialize'
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/client.rb:84:in `new'
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/client.rb:84:in `run'
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/application/solo.rb:191:in `run_application'
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/application/solo.rb:181:in `loop'
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/application/solo.rb:181:in `run_application'
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/../lib/chef/application.rb:62:in `run'
#   from /usr/lib/ruby/gems/1.8/gems/chef-0.9.8/bin/chef-solo:25
#   from /usr/bin/chef-solo:19:in `load'
#   from /usr/bin/chef-solo:19
begin
  set_unless[:tomcat6][:with_snmp]        = !languages[:java][:runtime][:name].match(/^OpenJDK/)
rescue NoMethodError
end
set_unless[:tomcat6][:java_home]        = "/usr/lib/jvm/java"
# snmp_opts fail with OpenJDK - results in silent exit(1) from the jre
if tomcat6[:with_snmp]
  set_unless[:tomcat6][:snmp_opts]      = "-Dcom.sun.management.snmp.interface=0.0.0.0 -Dcom.sun.management.snmp.acl=false -Dcom.sun.management.snmp.port=1161"
else
  set_unless[:tomcat6][:snmp_opts]      = ""
end
set_unless[:tomcat6][:java_opts]        = ""
set_unless[:tomcat6][:manager_user]     = "manager"
set_unless[:tomcat6][:manager_password] = pw
set_unless[:tomcat6][:permgen_min_free_in_mb] = 24
