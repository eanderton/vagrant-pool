require 'vagrant'
require 'mixlib/shellout'
require 'optparse'
require 'thread'

module Vagrant
  module Vmpool
    class PoolList < CommandBase
      
      def initialize(argv, env)
        @argv = argv
        @env  = env
        @logger = Log4r::Logger.new("vagrant::command::#{self.class.to_s.downcase}")
      end

      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant pool-list [pool-name]"
          o.separator ""
        end
        argv = parse_options(opts)
        filter_pool_name = validate_single_argv(argv, nil)
        machine_pools = get_filtered_pools(filter_pool_name)

        puts "Pooled machine definitions:"
        machine_pools.each do |pool_name, pool|
          pool.each do |name, machine|
            state = machine[:state]
            puts "#{name}: #{pool_name} - #{state}"
          end
        end
      end
    end

    class PoolUp < CommandBase
      def execute 
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant pool-up [pool-name]"
          o.separator ""
        end
        argv = parse_options(opts)
        filter_pool_name = validate_single_argv(argv, 'default')
        machines = get_filtered_pools(filter_pool_name)[filter_pool_name]
        machine_names = machines.keys.map { |k| k.to_s } 

        # TODO: refactor to VagrantPlugins::CommandUp::Command ?
        with_target_vms(machine_names) do |machine|
          machine.action(:up)
        end
      end
    end

    class PoolHalt < CommandBase
      def execute 
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant pool-halt [pool-name]"
          o.separator ""
        end
        argv = parse_options(opts)
        filter_pool_name = validate_single_argv(argv, 'default')
        machines = get_filtered_pools(filter_pool_name)[filter_pool_name]
        machine_names = machines.keys.map { |k| k.to_s } 

        # TODO: refactor to VagrantPlugins::CommandHalt::Command ?
        with_target_vms(machine_names) do |machine|
          machine.action(:halt)
        end
      end
    end

    class PoolSsh < CommandBase
      def execute
        with_config do 
          options = {
            :next => true
          }
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant pool-ssh [pool-name]"
            o.separator ""

            # TODO: add --next flag to build in pool-next behavior
            # TODO: loop mode?
          end
          argv = parse_options(opts)
          filter_pool_name = validate_single_argv(argv, 'default')

          # get current vm in pool
          current_name = get_current_name(filter_pool_name)
          
          # TODO: ensure system is running first?
          # TODO: refactor to VagrantPlugins::CommandSsh::Command ?
         
          thread = nil
          thread_ui = nil
          old_stderr = nil
          old_stdout = nil
          old_env_stderr = nil
          old_env_stdout = nil
          if options[:next]
            with_target_vms([current_name]) do |machine|
              # disable output for concurrent actions, so the SSH
              # prompt is usable
              thread_ui = machine.ui 
              old_stderr = thread_ui.stderr
              thread_ui.stderr = StringIO.new
              old_stdout = thread_ui.stdout
              thread_ui.stdout = StringIO.new
              old_env_stderr = @env.ui.stderr
              @env.ui.stderr = thread_ui.stderr
              old_env_stdout = @env.ui.stdout
              @env.ui.stdout = thread_ui.stdout 

              # run destroy+up in the background
              thread = Thread.new do
                machine.action(:destroy, force_confirm_destroy: { 
                  :ui=>thread_ui, :force=>true })
                machine.action(:up, { :ui=>thread_ui })
              end
            end
            current_name = get_next_name(filter_pool_name)
          end
         
          with_target_vms([current_name]) do |machine|
            puts "Using pool vm #{current_name}"
            machine.action(:ssh, ssh_opts: {:subprocess=>true})
          end

          if not thread.nil?
            # Turn UI back on and wait
            thread_ui.stderr = old_stderr
            thread_ui.stdout = old_stdout
            old_env_stderr.write(@env.ui.stderr.string)
            @env.ui.stderr = old_env_stderr
            old_env_stdout.write(@env.ui.stdout.string)
            @env.ui.stdout = old_env_stdout
            thread.join(THREAD_MAX_JOIN_TIMEOUT) while thread.alive?
          end
        end
      end
    end

    class PoolNext < CommandBase
      def execute
        with_config do 
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant pool-next [pool-name]"
            o.separator ""
          end
          argv = parse_options(opts)
          filter_pool_name = validate_single_argv(argv, 'default')
          # set next available in pool, and halt+destroy+up previous
          old_name = get_current_name(filter_pool_name)
          next_name = get_next_name(filter_pool_name)
          
          puts "Rotating pool to #{next_name}, rebuilding #{old_name}"
          # TODO: ensure new system is running?

          # TODO: refactor to VagrantPlugins command classes?
          with_target_vms([old_name]) do |machine|
            machine.action(:destroy, force_confirm_destroy: { :force=>true })
            machine.action(:up)
          end
        end
      end
    end
 
  end
end
