module MailManager
  class List
    # this class is immutable
    # any editable list attributes are in other classes
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def to_s
      @name
    end

    def lib
      self.class.lib
    end

    def self.lib
      MailManager::Lib.new
    end

    def self.create(params)
      lib.create_list(params)
    end

    def members
      lib.members_of(self)
    end
  end
end
