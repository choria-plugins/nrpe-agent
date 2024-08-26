module MCollective
  module Agent
    class Nrpe<RPC::Agent

      action "runallcommands" do
        reply[:commands] = {}
        p = Nrpe.all_command_plugins
        p.each do |name,cmd|
          exitcode, output = Nrpe.run(name)

          reply[:commands][name] = {
            :exitcode => exitcode,
            :output => output,
          }
        end
      end

      action "runcommand" do
        args = request[:args].to_s.split('!')
        reply[:exitcode], reply[:output] = Nrpe.run(request[:command], args)
        reply[:command] = request[:command]

        case reply[:exitcode]
          when 0
            reply.statusmsg = "OK"

          when 1
            reply.fail "WARNING"

          when 2
            reply.fail "CRITICAL"

          else
            reply.fail "UNKNOWN"
        end

        if reply[:output] =~ /^(.+)\|(.+)$/
          reply[:output] = $1
          reply[:perfdata] = $2
        else
          reply[:perfdata] = ""
        end
      end

      # Runs an Nrpe command and returns the command output and exitcode
      # If the command does not exist run will return exitcode 3.
      #
      # The Nrpe configuration directory and file containing checks
      # must be specified in server.cfg. In here, the user who should run
      # the check can also be specified.
      #
      # Example :
      #          plugin.nrpe.conf_dir = /etc/nagios/nrpe
      #          plugin.nrpe.conf_file = checks.nrpe
      #          plugin.nrpe.runas_user = nrpe
      def self.run(command, args=[])
        nrpe_command = Nrpe.plugin_for_command(command, args)

        return 3, "No such command: #{command}" unless nrpe_command

        output = ""
        config = Config.instance
        runas_user = config.pluginconf["nrpe.runas_user"] || nil
        nrpe_command = "sudo -u '%s' %s" % [runas_user, nrpe_command] if runas_user

        run_shell_cmd(nrpe_command)
      end

      def self.run_shell_cmd(command)
        output = ""

        shell = ::MCollective::Shell.new(command, {:stdout => output, :chomp => true})
        shell.runcommand

        [shell.status.exitstatus, output]
      end

      def self.plugin_for_command(command, args)
        plugins = Nrpe.all_command_plugins

        if plugins.include?(command)
          return self.expand_command_args(plugins[command], args)
        end

        return nil
      end

      def self.expand_command_args(command, args)
        copy = command.dup # work on a copy to avoid mutating our arguments
        args.each_with_index do |value, index|
          copy.gsub!(/\$ARG#{index + 1}\$/, value)
        end
        return copy
      end

      def self.all_command_plugins
        commands = {}
        fnames = []
        config = Config.instance

        fdir = config.pluginconf["nrpe.conf_dir"] || "/etc/nagios/nrpe.d"

        if config.pluginconf["nrpe.conf_file"]
          fnames << "#{fdir}/#{config.pluginconf['nrpe.conf_file']}"
        elsif config.pluginconf["nrpe.conf_path"]
          fnames |= Dir.glob(config.pluginconf["nrpe.conf_path"].split(':').map{|fdir| "#{fdir}/*.cfg"})
        else
          fnames |= Dir.glob("#{fdir}/*.cfg")
        end

        fnames.each do |fname|
          if File.exist?(fname)
            File.readlines(fname).each do |check|
              check.chomp!

              if check =~ /^command\[(.+?)\]\s*=\s*(.+)$/
                commands[$1] = $2
              end
            end
          end
        end

        return commands
      end
    end
  end
end
