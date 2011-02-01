require "singleton"
require "rubygems"
require "bundler/setup"
require "json"
require "open4"

require 'mailmanager/lib'
require 'mailmanager/list'

module MailManager
  @root = nil
  @python = '/usr/bin/env python'
  @debug = ENV['MAILMANAGER_DEBUG'] =~ /^(?:1|true|y|yes|on)$/i ? true : false

  def self.root=(root) #:nodoc:
    @root = root
  end

  def self.root #:nodoc:
    @root
  end

  def self.python=(python) #:nodoc:
    @python = python
  end

  def self.python #:nodoc:
    @python
  end

  def self.debug #:nodoc:
    @debug
  end

  # Call this method to start using MailManager. Give it the full path to your
  # Mailman installation. It will return an instance of MailManager::Base.
  def self.init(root)
    self.root = root
    Base.instance
  end

  # The MailManager::Base class is the root class for working with a Mailman
  # installation. You get an instance of it by calling
  # MailManager.init('/mailman/root').
  class Base
    include Singleton

    REQUIRED_BIN_FILES = ['list_lists', 'newlist', 'inject'] #:nodoc:

    def initialize #:nodoc:
      raise "Must set MailManager.root before calling #{self.class}.instance" if MailManager.root.nil?
      raise "#{root} does not exist" unless Dir.exist?(root)
      raise "#{root}/bin does not exist" unless Dir.exist?("#{root}/bin")
      REQUIRED_BIN_FILES.each do |bin_file|
        raise "#{root}/bin/#{bin_file} not found" unless File.exist?("#{root}/bin/#{bin_file}")
      end
      @lib = MailManager::Lib.new
    end

    # If you want to use a non-default python executable to run the Python
    # portions of this gem, set its full path here. Since we require Python
    # 2.6+ and some distros don't ship with that version, you can point this at
    # a newer Python you have installed. Defaults to /usr/bin/env python.
    def python=(python)
      MailManager.python = python
    end

    def python #:nodoc:
      MailManager.python
    end

    def root #:nodoc:
      MailManager.root
    end

    # Returns an array of MailManager::List instances of the lists in your
    # Mailman installation.
    def lists
      @lib.lists
    end

    # Only retrieves the list names, doesn't wrap them in MailManager::List
    # instances.
    def list_names
      @lib.list_names
    end

    # Create a new list. Returns an instance of MailManager::List. Params are:
    # * :name => 'new_list_name'
    # * :admin_email => 'admin@domain.com'
    # * :admin_password => 'supersecret'
    def create_list(params)
      MailManager::List.create(params)
    end

    # Get an existing list as a MailManager::List instance. Raises an exception if
    # the list doesn't exist.
    def get_list(list_name)
      @lib.get_list(list_name)
    end

    def delete_list(list_name)
      MailManager::List.delete(list_name)
    end
  end

end
