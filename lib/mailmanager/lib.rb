module MailManager

  class MailmanExecuteError < StandardError #:nodoc:
  end

  class ListNotFoundError < StandardError #:nodoc:
  end

  class ListNameConflictError < StandardError #:nodoc:
  end

  class ModeratorNotFoundError < StandardError #:nodoc:
  end

  class ModeratorAlreadyExistsError < StandardError #:nodoc:
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

    def find_member(regex)
      regex = regex.source if regex.is_a? Regexp
      cmd = :find_member
      out = command(cmd, {:regex => regex})
      parse_output(cmd, out)
    end

    def create_list(params)
      raise ArgumentError, "Missing :name param" if params[:name].nil?
      list_name = params[:name]
      raise ListNameConflictError, "List \"#{list_name}\" already exists" if list_names.include?(list_name)
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
      raise ListNotFoundError, "#{params[:name]} does not exist" unless list_names.include?(params[:name])
      cmd = :rmlist
      out = command(cmd, params)
      parse_output(cmd, out)
    end

    def inject(list, message, queue=nil)
      cmd = :inject
      params = {:listname => list.name, :stdin => message}
      params[:queue] = queue unless queue.nil?
      command(cmd, params)
      {'result' => 'success'}
    end

    def list_address(list)
      withlist_command(:getListAddress, list)
    end

    def regular_members(list)
      withlist_command(:getRegularMemberKeys, list)
    end

    def digest_members(list)
      withlist_command(:getDigestMemberKeys, list)
    end

    def add_member(list, member)
      withlist_command(:AddMember, list, member)
    end

    def approved_add_member(list, member)
      withlist_command(:ApprovedAddMember, list, member)
    end

    def delete_member(list, email)
      withlist_command(:DeleteMember, list, email)
    end

    def approved_delete_member(list, email)
      withlist_command(:ApprovedDeleteMember, list, email)
    end

    def moderators(list)
      withlist_command(:moderator, list)
    end

    def add_moderator(list, email)
      if moderators(list)['return'].include?(email)
        raise ModeratorAlreadyExistsError, "#{email} is already a moderator of #{list.name}"
      end
      withlist_command('moderator.append', list, email)
    end

    def delete_moderator(list, email)
      unless moderators(list)['return'].include?(email)
        raise ModeratorNotFoundError, "#{email} is not a moderator of #{list.name}"
      end
      withlist_command('moderator.remove', list, email)
    end

    def web_page_url(list)
      withlist_command('web_page_url', list)
    end

    def request_email(list)
      withlist_command(:GetRequestEmail, list)
    end

    def description(list)
      withlist_command(:description, list)
    end

    def set_description(list, desc)
      withlist_command(:description, list, desc)
    end

    def subject_prefix(list)
      withlist_command(:subject_prefix, list)
    end

    def set_subject_prefix(list, sp)
      withlist_command(:subject_prefix, list, sp)
    end

    def host_name(list)
      withlist_command(:host_name, list)
    end

    def set_host_name(list, host_name)
      withlist_command(:host_name, list, host_name)
    end

    private

    def withlist_command(wlcmd, list, *args)
      params = {:name => list.name, :wlcmd => wlcmd}
      params[:arg] = args[0] unless args[0].nil?
      out = command(:withlist, params)
      parse_json_output(out)
    end

    def command(cmd, params = {})
      mailman_cmd = "#{MailManager.python} #{mailmanager.root}/bin/#{cmd.to_s} "
      # delete params as we handle them explicitly
      stdin = nil
      stdin = params.delete(:stdin) if params.respond_to?(:has_key?) && params.has_key?(:stdin)
      case cmd
      when :newlist
        mailman_cmd += "-q "
        raise ArgumentError, "Missing :name param" if params[:name].nil?
        raise ArgumentError, "Missing :admin_email param" if params[:admin_email].nil?
        raise ArgumentError, "Missing :admin_password param" if params[:admin_password].nil?
        mailman_cmd_suffix = [:name, :admin_email, :admin_password].map { |key|
          escape(params.delete(key))
        }.join(' ')
        mailman_cmd += "#{mailman_cmd_suffix} "
      when :rmlist
        raise ArgumentError, "Missing :name param" if params[:name].nil?
        mailman_cmd += "#{escape(params.delete(:name))} "
      when :find_member
        raise ArgumentError, "Missing :regex param" if params[:regex].nil?
        mailman_cmd += "#{escape(params.delete(:regex))} "
      when :withlist
        raise ArgumentError, "Missing :name param" if params[:name].nil?
        proxy_path = File.dirname(__FILE__)
        mailman_cmd = "PYTHONPATH=#{proxy_path} #{mailman_cmd}"
        mailman_cmd += "-q -r listproxy.command #{escape(params.delete(:name))} " +
                       "#{params.delete(:wlcmd)} "
        if !params[:arg].nil? && params[:arg].length > 0
          mailman_cmd += "#{escape(params.delete(:arg))} "
        end
      end

      # assume any leftover params are POSIX-style args
      mailman_cmd += params.keys.map { |k| "--#{k}=#{escape(params[k])}" }.join(' ')
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
      when :find_member
        matches = {}
        puts "Output from Mailman:\n#{output}" if MailManager.debug
        last_member = nil
        output.split("\n").each do |line|
          if line =~ /^(.+) found in:/
            puts "Found member #{$1}" if MailManager.debug
            last_member = $1
            matches[last_member] = []
          elsif line =~ /^\s*(.+?)$/
            puts "Found list #{$1} for member #{last_member}" if MailManager.debug
            matches[last_member] << $1
          end
        end
        return_obj = matches
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
