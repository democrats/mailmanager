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
      regular_members + digest_members
    end

    def regular_members
      lib.regular_members_of(self)
    end

    def digest_members
      lib.digest_members_of(self)
    end

    def add_member(email, name='')
      add_member_using(:add_member, email, name)
    end

    def add_approved_member(email, name='')
      add_member_using(:add_approved_member, email, name)
    end

    private

    def add_member_using(method, email, name)
      if name.length > 0
        member = "#{name} <#{email}>"
      else
        member = email
      end
      result = lib.send(method, self, member)
      result['result'].to_sym
    end
  end
end
