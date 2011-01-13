# Add the directory containing this file to the start of the load path if it
# isn't there already.
#$:.unshift(File.dirname(__FILE__)) unless
#  $:.include?(File.dirname(__FILE__)) ||
#    $:.include?(File.expand_path(File.dirname(__FILE__)))

module MailManager

  class MailmanExecuteError < StandardError
  end

  class Lib

    def mailmanager
      MailManager::Base.instance
    end

    def lists
      cmd = :list_lists
      out = command(cmd)
      parse_output(cmd, out)
    end

    def create_list(params)
      cmd = :newlist
      out = command(cmd, params)
      parse_output(cmd, out)
    end

    def regular_members(list)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :getRegularMemberKeys)
      parse_json_output(out)
    end

    def digest_members(list)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :getDigestMemberKeys)
      parse_json_output(out)
    end

    def add_member(list, member)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :AddMember, :arg => member)
      parse_json_output(out)
    end

    def approved_add_member(list, member)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :ApprovedAddMember,
                    :arg => member)
      parse_json_output(out)
    end

    def delete_member(list, email)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :DeleteMember,
                    :arg => email)
      parse_json_output(out)
    end

    def approved_delete_member(list, email)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :ApprovedDeleteMember,
                    :arg => email)
      parse_json_output(out)
    end

    def moderators(list)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :moderator)
      parse_json_output(out)
    end

    def add_moderator(list, email)
      if moderators(list)['return'].include?(email)
        return {'result' => 'already_a_moderator'}
      end
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => 'moderator.append',
                    :arg => email)
      parse_json_output(out)
    end

    def delete_moderator(list, email)
      raise "#{email} is not a moderator" unless moderators(list)['return'].include?(email)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => 'moderator.remove',
                    :arg => email)
      parse_json_output(out)
    end

    def inject(list, message, queue=nil)
      cmd = :inject
      params = {:listname => list.name, :stdin => message}
      params['queue'] = queue unless queue.nil?
      command(cmd, params)
    end

    def command(cmd, opts = {})
      mailman_cmd = "#{mailmanager.root}/bin/#{cmd.to_s} "
      # delete opts as we handle them explicitly
      stdin = nil
      stdin = opts.delete(:stdin) if opts.has_key?(:stdin)
      case cmd
      when :newlist
        mailman_cmd += "-q "
        raise ArgumentError, "Missing :name param" if opts[:name].nil?
        raise ArgumentError, "Missing :admin_email param" if opts[:admin_email].nil?
        raise ArgumentError, "Missing :admin_password param" if opts[:admin_password].nil?
        mailman_cmd_suffix = [:name, :admin_email, :admin_password].map { |key|
          escape(opts.delete(key))
        }.join(' ')
        mailman_cmd += "#{mailman_cmd_suffix} "
      when :withlist
        raise ArgumentError, "Missing :name param" if opts[:name].nil?
        proxy_path = File.dirname(__FILE__)
        mailman_cmd = "PYTHONPATH=#{proxy_path} #{mailman_cmd}"
        mailman_cmd += "-q -r listproxy.command #{escape(opts.delete(:name))} " +
                       "#{opts.delete(:wlcmd)} "
        if !opts[:arg].nil? && opts[:arg].length > 0
          mailman_cmd += "#{escape(opts.delete(:arg))} "
        end
      end

      # assume any leftover opts are POSIX-style args
      mailman_cmd += opts.keys.map { |k| "--#{k}=#{escape(opts[k])}" }.join(' ')
      mailman_cmd += ' ' if mailman_cmd[-1,1] != ' '
      mailman_cmd += "2>&1"
      if MailManager.debug
        puts "Running mailman command: #{mailman_cmd}"
        puts " with stdin: #{stdin}" unless stdin.nil?
      end
      out, process = run_command(mailman_cmd, stdin)

      if process.exitstatus > 0
        raise MailManager::MailmanExecuteError.new(mailman_cmd + ':' + out.to_s)
      end
      out
    end

    def run_command(mailman_cmd, stdindata=nil)
      output = nil
      process = Open4::popen4(mailman_cmd) do |pid, stdin, stdout, stderr|
        if !stdindata.nil?
          stdin.puts(stdindata)
          stdin.close
        end
        output = stdout.gets
      end
      [output, process]
    end

    def escape(s)
      # no idea what this does, stole it from the ruby-git gem
      escaped = s.to_s.gsub('\'', '\'\\\'\'')
      %Q{"#{escaped}"}
    end

    def parse_output(mailman_cmd, output)
      case mailman_cmd
      when :newlist
        list_name = nil
        output.split("\n").each do |line|
          if match = /^##\s+(.+?)mailing\s+list\s*$/.match(line)
            list_name = match[1]
          end
        end
        raise "Error getting name of newly created list" if list_name.nil?
        return_obj = MailManager::List.new(list_name)
      when :list_lists
        lists = []
        output.split("\n").each do |line|
          next if line =~ /^\d+ matching mailing lists found:$/
          /^\s*(.+?)\s+-\s+(.+)$/.match(line) do |m|
            lists << MailManager::List.new(m[1])
          end
        end
        return_obj = lists
      end
      return_obj
    end

    def parse_json_output(json)
      result = JSON.parse(json)
      if result.is_a?(Hash) && !result['error'].nil?
        raise MailmanExecuteError, result['error']
      end
      result
    end
  end
end
