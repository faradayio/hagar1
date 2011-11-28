hagar_root = File.expand_path File.join(File.dirname(__FILE__))

Vagrant::Config.run do |config|
  config.vm.box = "base"
  config.vm.customize do |vm|
    vm.memory_size = 512
  end
  config.vm.provision :chef_solo do |chef|
    chef.json[:hagar_net] = ENV['NET']
    chef.json[:hagar_apps] = Dir[File.join(hagar_root, 'apps_enabled', '*')].map { |name| File.basename(name) }
    chef.json[:hagar_gems] = Dir[File.join(hagar_root, 'gems_enabled', '*')].map { |name| File.basename(name) }
    # chef.json[:recipes] = ['vagrant_main']
    chef.cookbooks_path = "vagrant/chef-repo/cookbooks"
    chef.run_list.clear
    chef.add_recipe "0_vagrant_main"
  end
  config.vm.forward_port "ssh", 22, 2222
  config.vm.forward_port "web", 80, 4567
  config.vm.forward_port "web2", 8080, 5678
  config.vm.forward_port "web3", 8090, 6789
  config.vm.forward_port "web4", 5005, 5679
end
