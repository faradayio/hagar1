hagar_root = File.expand_path(File.join(File.dirname(__FILE__), 'apps_enabled'))
hagar_apps = Dir[File.join(hagar_root, '*')].map { |name| File.basename(name) }
puts %{
Found these apps: (in #{hagar_root})
\t#{hagar_apps.join("\n\t")}
}

Vagrant::Config.run do |config|
  config.vm.box = "base"
  config.vm.base_mac = "0800279C2E41"
  config.vm.customize do |vm|
    vm.memory_size = 640
  end
  config.chef.json[:hagar_apps] = hagar_apps
  config.chef.json[:recipes] = ['vagrant_main']
  config.vm.provisioner = :chef_solo
  config.chef.cookbooks_path = "vagrant/chef-repo/cookbooks"
  # don't collide with cm1
  config.vm.forward_port "ssh", 22, 2222
  config.vm.forward_port "web", 80, 4567
end
