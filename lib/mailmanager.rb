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

  def self.root=(root)
    @root = root
  end

  def self.root
    @root
  end

  def self.python=(python)
    @python = python
  end

  def self.python
    @python
  end

  def self.debug
    @debug
  end

  def self.init(root)
    self.root = root
    Base.instance
  end

  class Base
    include Singleton

    REQUIRED_BIN_FILES = ['list_lists', 'newlist', 'inject']

    def initialize
      raise "Must set MailManager.root before calling #{self.class}.instance" if MailManager.root.nil?
      raise "#{root} does not exist" unless Dir.exist?(root)
      raise "#{root}/bin does not exist" unless Dir.exist?("#{root}/bin")
      REQUIRED_BIN_FILES.each do |bin_file|
        raise "#{root}/bin/#{bin_file} not found" unless File.exist?("#{root}/bin/#{bin_file}")
      end
      @lib = MailManager::Lib.new
    end

    def python=(python)
      MailManager.python = python
    end

    def python
      MailManager.python
    end

    def root
      MailManager.root
    end

    def lists
      @lib.lists
    end

    def list_names
      lists.map { |list| list.name }
    end

    def create_list(params)
      MailManager::List.create(params)
    end

    def get_list(list_name)
      raise "#{list_name} list does not exist" unless list_names.include?(list_name.downcase)
      MailManager::List.new(list_name)
    end
  end

end
