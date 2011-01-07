require "rubygems"
require "bundler/setup"

require 'mailmanager/lib'
require 'mailmanager/list'

module MailManager
  class Base
    attr_reader :root

    REQUIRED_BIN_FILES = ['add_members', 'remove_members', 'list_lists',
                          'list_members', 'newlist', 'rmlist', 'sync_members']

    def initialize(mailman_root)
      raise ArgumentError unless Dir.exist?(mailman_root)
      raise ArgumentError unless Dir.exist?("#{mailman_root}/bin")
      REQUIRED_BIN_FILES.each do |bin_file|
        raise ArgumentError unless File.exist?("#{mailman_root}/bin/#{bin_file}")
      end
      @root = mailman_root
    end
  end

end
