module MailManager

  # The List class represents mailing lists in Mailman.
  # Typically you get them by doing one of these things:
  # mm = MailManager.init('/mailman/root')
  # mylist = mm.get_list('list_name')
  # OR
  # mylist = mm.create_list(:name => 'list_name', :admin_email =>
  # 'foo@bar.com', :admin_password => 'supersecret')
  #

  class List
    # The name of the list
    attr_reader :name

    # This doesn't do any checking to see whether or not the requested list
    # exists or not. Better to use MailManager::Base#get_list instead.
    def initialize(name)
      @name = name
    end

    def to_s #:nodoc:
      @name
    end

    def lib #:nodoc:
      self.class.lib
    end

    def self.lib #:nodoc:
      MailManager::Lib.new
    end

    def self.create(params) #:nodoc:
      lib.create_list(params)
    end

    # Returns the list's email address
    def address
      result = lib.list_address(self)
      result['return']
    end

    # Returns all list members (regular & digest) as an array
    def members
      regular_members + digest_members
    end

    # Returns just the regular list members (no digest members) as an array
    def regular_members
      result = lib.regular_members(self)
      result['return']
    end

    # Returns just the digest list members (no regular members) as an array
    def digest_members
      result = lib.digest_members(self)
      result['return']
    end

    # Adds a new list member, subject to the list's subscription rules
    def add_member(email, name='')
      add_member_using(:add_member, email, name)
    end

    # Adds a new list member, bypassing the list's subscription rules
    def approved_add_member(email, name='')
      add_member_using(:approved_add_member, email, name)
    end

    # Deletes a list member, subject to the list's unsubscription rules
    def delete_member(email)
      delete_member_using(:delete_member, email)
    end

    # Deletes a list member, bypassing the list's unsubscription rules
    def approved_delete_member(email, name='')
      delete_member_using(:approved_delete_member, email)
    end

    # Returns the list of moderators as an array of email addresses
    def moderators
      result = lib.moderators(self)
      result['return']
    end

    # Adds a new moderator to the list. Returns :already_a_moderator if the
    # requested new moderator is already a moderator.
    def add_moderator(email)
      result = lib.add_moderator(self, email)
      result['result'].to_sym
    end

    # Deletes a moderator from the list. Returns :not_a_moderator if the
    # requested deletion isn't a moderator.
    def delete_moderator(email)
      result = lib.delete_moderator(self, email)
      result['result'].to_sym
    end

    # Injects a message into the list.
    def inject(from, subject, message)
      inject_message =<<EOF
From: #{from}
To: #{address}
Subject: #{subject}

#{message}
EOF
      lib.inject(self, inject_message)
    end

    # Returns the info URL for the list
    def info_url
      result = lib.web_page_url(self)
      root = result['return']
      root += "/" unless root[-1,1] == '/'
      "#{root}listinfo/#{name}"
    end

    # Returns the request email address for the list
    def request_email
      result = lib.request_email(self)
      result['return']
    end

    # Returns the list description
    def description
      result = lib.description(self)
      result['return']
    end

    # Sets the list description to a new value
    def description=(desc)
      result = lib.set_description(self, desc)
      result['result'].to_sym
    end

    # Returns the list's subject prefix
    def subject_prefix
      result = lib.subject_prefix(self)
      result['return']
    end

    # Sets the list's subject prefix to a new value. Remember to leave a space
    # at the end (assuming you want one, and you probably do).
    def subject_prefix=(sp)
      result = lib.set_subject_prefix(self, sp)
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
