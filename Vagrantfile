%w{ kayak1 data1 wlpf1 }.each do |name|
  unless File.readable?(File.expand_path(File.join(File.dirname(__FILE__), name)))
    raise "You're missing a symbolic link to #{name}. Please create it with 'ln -s SOURCE_DIR #{name}'"
  end
end

Vagrant::Config.run do |config|
  config.vm.box = "base"
  config.vm.base_mac = "0800279C2E41"
  config.vm.customize do |vm|
    vm.memory_size = 512
  end
  config.chef.json[:recipes] = ['vagrant_main']
  config.vm.provisioner = :chef_solo
  config.chef.cookbooks_path = "vagrant/chef-repo/cookbooks"
  # don't collide with cm1
  config.vm.forward_port "ssh", 22, 2223
  config.vm.forward_port "web", 80, 4568
end
