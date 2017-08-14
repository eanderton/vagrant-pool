Vagrant.configure(2) do |config|
  config.vm.box = "bento/centos-7.3"
  config.vm.provider :virtualbox do |vb|
    vb.memory = 4096
    vb.cpus = 2
   	# vb.customize ["modifyvm", :id, "--memory", "4096", "--cpu", "2",  "--ioapic", "on"]
  end
  config.vm.synced_folder ".", "/vagrant"
  config.vmpool.name = "default"
  config.vm.provision "shell", privileged: true, inline: <<-SHELL
  SHELL

  (0..3).each do |i|
    config.vm.define "node-#{i}" do |node|
      #node.name = "node-#{i}"
    end
  end
end

