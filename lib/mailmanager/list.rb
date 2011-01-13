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
      result = lib.regular_members(self)
      result['return']
    end

    def digest_members
      result = lib.digest_members(self)
      result['return']
    end

    def add_member(email, name='')
      add_member_using(:add_member, email, name)
    end

    def approved_add_member(email, name='')
      add_member_using(:approved_add_member, email, name)
    end

    def delete_member(email)
      delete_member_using(:delete_member, email)
    end

    def approved_delete_member(email, name='')
      delete_member_using(:approved_delete_member, email)
    end

    def moderators
      result = lib.moderators(self)
      result['return']
    end

    def add_moderator(email)
      result = lib.add_moderator(self, email)
      result['result'].to_sym
    end

    def delete_moderator(email)
      result = lib.delete_moderator(self, email)
      result['result'].to_sym
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

    def delete_member_using(method, email)
      result = lib.send(method, self, email)
      result['result'].to_sym
    end
  end
end
