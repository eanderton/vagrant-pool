require 'yaml'

module Vagrant
  module Vmpool
    
    # TODO: i18n support
    class GeneralError < Vagrant::Errors::VagrantError
      error_key(nil) #:vmpool_plugin_error)
    end

    class CommandBase < Vagrant.plugin('2', :command)
      
      def get_pooled_machines(filter_pool_name=nil)
        @all_pools ||= begin
          pools = {}

          # build cross-reference for machine_index
          machine_index = {}
          @env.machine_index.each do |entry|
            machine_index[entry.name] = entry
          end

          vf = @env.vagrantfile
          vf.machine_names.each do |machine_name|
            # get machine config and name
            cfg = vf.machine_config(machine_name, nil, nil)
            vmpool = cfg[:config].vmpool

            pool = pools[vmpool.name] = pools.fetch(vmpool.name, {})
            idx = machine_index.fetch(machine_name.to_s, nil)
            pool[machine_name] = {
              :cfg => cfg,
              :vmpool => vmpool,
              :state => idx.nil? ? 'Not provisioned' : idx.state,
            }
          end
          pools
        end
        
        # filter based on filter argument
        if filter_pool_name.nil?
          @all_pools
        else
          @all_pools.fetch(filter_pool_name, {})
        end
      end

      def validate_single_argv(argv, default=nil)
        if argv.length > 1
          raise GeneralError.new, 'Too many arguments'
        end
        argv.fetch(0, default)
      end

      def get_filtered_pools(filter_pool_name)
        pools = get_pooled_machines(filter_pool_name)
        if pools.empty?
          raise GeneralError.new, 'No pooled machines in filter'
        end 
        pools
      end

      def config_file_path
        File.join(@env.local_data_path, 'vmpool.yaml')
      end

      def _load_pool_config
        if File.exist?(config_file_path)
          @pool_config = YAML.load_file(config_file_path)
        else
          @pool_config = {}
        end

        # reconcile config
        cfg_pools = @pool_config.fetch('pools', {})
        get_pooled_machines.each do |pool_name, pool|
          pool = cfg_pools[pool_name] = cfg_pools.fetch(pool_name, {})
          pool['current'] = pool.fetch('current', @all_pools[pool_name].keys[0].to_s)
        end
        @pool_config['pools'] = cfg_pools
      end
      
      def _save_pool_config
        File.open(config_file_path, "wt") do |f|
          f.write(YAML.dump(@pool_config))
        end
      end

      def with_config(&block)
        _load_pool_config
        block.call()
        _save_pool_config
      end

      def get_current_name(pool_name)
        @pool_config['pools'][pool_name]['current'].to_s
      end

      def get_next_name(pool_name)
        pool = @all_pools[pool_name]
        current_name = get_current_name(pool_name)
        
        # get next name in set
        idx = pool.keys.map{ |x| x.to_s }.index(current_name)
        if idx.nil?
          idx = 0
        else
          idx = idx + 1
        end
        if idx >= pool.keys.length
          idx = 0 
        end
        value = pool.keys[idx].to_s
        @pool_config['pools'][pool_name]['current'] = value
        value
      end

    end
  end
end
