module Vagrant
  module Vmpool
    class Plugin < Vagrant.plugin("2")
      name "Vmpool"
      description <<-EOF
      This plugin provides a pooling implementation for faster 'vagrant up' times.
      EOF

      command 'pool-list' do
        require_relative 'command'
        PoolList
      end
      
      command 'pool-up' do
        require_relative 'command'
        PoolUp
      end

      command 'pool-halt' do
        require_relative 'command'
        PoolHalt
      end

      command 'pool-ssh' do
        require_relative 'command'
        PoolSsh
      end

      command 'pool-next' do
        require_relative 'command'
        PoolNext
      end

      config 'vmpool' do
        require_relative 'config'
        Config
      end
    end
  end
end
