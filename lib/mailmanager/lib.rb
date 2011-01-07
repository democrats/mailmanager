# Add the directory containing this file to the start of the load path if it
# isn't there already.
#$:.unshift(File.dirname(__FILE__)) unless
#  $:.include?(File.dirname(__FILE__)) ||
#    $:.include?(File.expand_path(File.dirname(__FILE__)))

module MailManager

  class MailmanExecuteError < StandardError
  end

  class Lib

    def initialize(mailman)
      @mailman = mailman
    end

    def lists
      cmd = :list_lists
      out = command(cmd)
      parse_output(cmd, out)
    end

    def command(cmd, opts = [])
      opts = [opts].flatten.map {|s| escape(s) }.join(' ')
      mailman_cmd = "#{@mailman.root}/bin/#{cmd.to_s} #{opts} 2>&1"

      out = run_command(mailman_cmd)

      if $?.exitstatus > 0
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
      when :list_lists
        lists = []
        output.split("\n").each do |line|
          next if line =~ /^\d+ matching mailing lists found:$/
          /^\s*(.+?)\s+-\s+(.+)$/.match(line) do |m|
            lists << MailManager::List.new(@mailman, m[1])
          end
        end
        return_obj = lists
      end
      return_obj
    end
  end
end
