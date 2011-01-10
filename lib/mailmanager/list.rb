module MailManager
  class List
    attr_reader :name

    def initialize(mailman, name)
      @mailman = mailman
      @name = name
    end

    def to_s
      @name
    end

    def self.create(mailman, params)
      lib = MailManager::Lib.new(mailman)
      lib.create_list(params)
    end

  end
end
