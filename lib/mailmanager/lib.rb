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

    def regular_members_of(list)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :getRegularMemberKeys)
      parse_json_output(out)
    end

    def digest_members_of(list)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :getDigestMemberKeys)
      parse_json_output(out)
    end

    def command(cmd, opts = {})
      case cmd
      when :newlist
        mailman_cmd = "#{mailmanager.root}/bin/#{cmd.to_s} -q "
        raise ArgumentError, "Missing :name param" if opts[:name].nil?
        raise ArgumentError, "Missing :admin_email param" if opts[:admin_email].nil?
        raise ArgumentError, "Missing :admin_password param" if opts[:admin_password].nil?
        mailman_cmd_suffix = [:name, :admin_email, :admin_password].map { |key|
          escape(opts.delete(key))
        }.join(' ')
        mailman_cmd += opts.keys.map { |k| "--#{escape(k)}=#{escape(opts[k])}" }.join(' ')
        mailman_cmd += "#{mailman_cmd_suffix} 2>&1"
      when :withlist
        raise ArgumentError, "Missing :name param" if opts[:name].nil?
        proxy_path = File.dirname(__FILE__)
        mailman_cmd = "PYTHONPATH=#{proxy_path} #{mailmanager.root}/bin/#{cmd.to_s} " +
                      "-q -r listproxy.command #{escape(opts.delete(:name))} " +
                      "#{opts.delete(:wlcmd)}"
      else
        # no options allowed in the fallback case
        mailman_cmd = "#{mailmanager.root}/bin/#{cmd.to_s} 2>&1"
      end

      out = run_command(mailman_cmd)

      if !$?.nil? && $?.exitstatus > 0
        raise MailManager::MailmanExecuteError.new(mailman_cmd + ':' + out.to_s)
      end
      out
    end

    def run_command(mailman_cmd)
      `#{mailman_cmd}`.chomp
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
      JSON.parse(json)
    end
  end
end
