hagar_root = File.expand_path File.join(File.dirname(__FILE__))
hagar_apps = Dir[File.join(hagar_root, 'apps_enabled', '*')].map { |name| File.basename(name) }
hagar_gems = Dir[File.join(hagar_root, 'gems_enabled', '*')].map { |name| File.basename(name) }

Vagrant::Config.run do |config|
  config.vm.box = "lucid32"
  config.vm.customize do |vm|
    vm.memory_size = 512
  end
  config.chef.json[:hagar_apps] = hagar_apps
  config.chef.json[:hagar_gems] = hagar_gems
  config.chef.json[:recipes] = ['vagrant_main']
  config.vm.provisioner = :chef_solo
  config.chef.cookbooks_path = "vagrant/chef-repo/cookbooks"
  config.vm.forward_port "ssh", 22, 2222
  config.vm.forward_port "web", 80, 4567
end
