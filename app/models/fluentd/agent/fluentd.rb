class Fluentd
  class Agent
    class Fluentd
      include Common

      def self.default_options
        {
          :pid_file => "/var/run/fluent.pid",
          :log_file => "/var/log/fluent.log",
          :config_file => "/etc/fluent/fluent.conf",
        }
      end

      def options_to_argv
        argv = ""
        argv << " --use-v1-config"
        argv << " -c #{config_file}"
        argv << " -d #{pid_file}"
        argv << " -o #{log_file}"
        argv
      end

      # return value is status_after_this_method_called == started
      def start
        return true if running?
        actual_start
      end

      # return value is status_after_this_method_called == stopped
      def stop
        return true unless running?
        actual_stop
      end

      # return value is status_after_this_method_called == started
      def restart
        stop && start
      end

      def reload # NOTE: does not used currently, and td-agent has no restart command
        return false unless running?
        actual_restart
      end

      private

      def validate_fluentd_options
        system("bundle exec fluentd --dry-run #{options_to_argv}")
      end

      def actual_start
        return unless validate_fluentd_options
        spawn("bundle exec fluentd #{options_to_argv}")
        wait_starting
      end

      def actual_stop
        if Process.kill(:TERM, pid)
          File.unlink(pid_file)
          true
        end
      end

      def actual_restart
        Process.kill(:HUP, pid)
      end

      def wait_starting
        begin
          timeout(wait_process_starting_seconds) do
            loop do
              break if pid && Process.kill(0, pid)
              sleep 0.01
            end
          end
          true
        rescue TimeoutError
          false
        end
      end
    end
  end
end
