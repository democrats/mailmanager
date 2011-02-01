module MailManager

  class MailmanExecuteError < StandardError #:nodoc:
  end

  class ListNotFoundError < StandardError #:nodoc:
  end

  class Lib #:nodoc:all

    def mailmanager
      MailManager::Base.instance
    end

    def lists
      cmd = :list_lists
      out = command(cmd)
      parse_output(cmd, out)
    end

    def list_names
      lists.map { |list| list.name }
    end

    def create_list(params)
      raise ArgumentError, "Missing :name param" if params[:name].nil?
      list_name = params[:name]
      cmd = :newlist
      # create the list
      out = command(cmd, params)
      # get the new list
      begin
        get_list(list_name)
      rescue ListNotFoundError
        raise MailmanExecuteError, "List creation failed: #{out}"
      end
    end

    def get_list(list_name)
      raise ListNotFoundError, "#{list_name} does not exist" unless list_names.include?(list_name)
      MailManager::List.new(list_name)
    end

    def delete_list(params)
      params = {:name => params} unless params.respond_to?(:has_key?)
      cmd = :rmlist
      out = command(cmd, params)
      parse_output(cmd, out)
    end

    def list_address(list)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :getListAddress)
      parse_json_output(out)
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
      unless moderators(list)['return'].include?(email)
        return {'result' => 'not_a_moderator'}
      end
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => 'moderator.remove',
                    :arg => email)
      parse_json_output(out)
    end

    def inject(list, message, queue=nil)
      cmd = :inject
      params = {:listname => list.name, :stdin => message}
      params[:queue] = queue unless queue.nil?
      command(cmd, params)
    end

    # TODO: DRY this up!

    def web_page_url(list)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => 'web_page_url')
      parse_json_output(out)
    end

    def request_email(list)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :GetRequestEmail)
      parse_json_output(out)
    end

    def description(list)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :description)
      parse_json_output(out)
    end

    def subject_prefix(list)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :subject_prefix)
      parse_json_output(out)
    end

    def set_description(list, desc)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :description, :arg => desc)
      parse_json_output(out)
    end

    def set_subject_prefix(list, sp)
      cmd = :withlist
      out = command(cmd, :name => list.name, :wlcmd => :subject_prefix, :arg => sp)
      parse_json_output(out)
    end

    def command(cmd, opts = {})
      mailman_cmd = "#{mailmanager.root}/bin/#{cmd.to_s} "
      # delete opts as we handle them explicitly
      stdin = nil
      stdin = opts.delete(:stdin) if opts.respond_to?(:has_key?) && opts.has_key?(:stdin)
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
      when :rmlist
        raise ArgumentError, "Missing :name param" if opts[:name].nil?
        mailman_cmd += "#{escape(opts.delete(:name))} "
      when :withlist
        raise ArgumentError, "Missing :name param" if opts[:name].nil?
        proxy_path = File.dirname(__FILE__)
        mailman_cmd = "PYTHONPATH=#{proxy_path} #{MailManager.python} #{mailman_cmd}"
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
        output = stdout.read
      end
      [output, process]
    end

    def self.escape(s)
      escaped = s.to_s.gsub('\'', '\'\\\'\'')
      %Q{"#{escaped}"}
    end

    def escape(s)
      self.class.escape(s)
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
        raise MailmanExecuteError, "Error getting name of newly created list. Mailman sent:\n#{output}" if list_name.nil?
        return_obj = MailManager::List.new(list_name)
      when :rmlist
        return_obj = output =~ /Removing list info/
      when :list_lists
        lists = []
        puts "Output from Mailman:\n#{output}" if MailManager.debug
        output.split("\n").each do |line|
          next if line =~ /^\d+ matching mailing lists found:$/
          /^\s*(.+?)\s+-\s+(.+)$/.match(line) do |m|
            puts "Found list #{m[1]}" if MailManager.debug
            lists << MailManager::List.new(m[1].downcase)
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
