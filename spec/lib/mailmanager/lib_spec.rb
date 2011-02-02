require 'spec_helper'

describe MailManager::Lib do
  let(:mailmanager) { mock(MailManager) }
  let(:subject)     { MailManager::Lib.new }
  let(:fake_root)   { '/foo/bar' }
  let(:process)     { mock(Process::Status) }
  let(:list_result) { <<EOF
3 matching mailing lists found:
        Foo - [no description available]
     BarBar - Dummy list
    Mailman - Mailman site list
EOF
  }
  let(:list_result_after_create) { list_result + "\n        Bar - [no description available]\n" }

  before :each do
    subject.stub(:mailmanager).and_return(mailmanager)
    mailmanager.stub(:root).and_return(fake_root)
    process.stub(:exitstatus).and_return(0)
  end

  describe "#lists" do
    it "should return all existing lists" do
      subject.stub(:run_command).with("#{fake_root}/bin/list_lists 2>&1", nil).
        and_return([list_result, process])
      subject.lists.should have(3).lists
    end
  end

  describe "#create_list" do
    before :each do
      subject.stub(:run_command).with("#{fake_root}/bin/list_lists 2>&1", nil).
        and_return([list_result, process])
    end

    it "should raise an argument error if list name is missing" do
      lambda {
        subject.create_list(:admin_email => 'foo@bar.baz', :admin_password => 'qux')
      }.should raise_error(ArgumentError)
    end

    it "should raise an argument error if list admin email is missing" do
      lambda {
        subject.create_list(:name => 'bar', :admin_password => 'qux')
      }.should raise_error(ArgumentError)
    end

    it "should raise an argument error if admin password is missing" do
      lambda {
        subject.create_list(:name => 'bar', :admin_email => 'foo@bar.baz')
      }.should raise_error(ArgumentError)
    end

    context "with valid list params" do
      let(:new_aliases) {
        ['bar:              "|/foo/bar/mail/mailman post bar"',
         'bar-admin:        "|/foo/bar/mail/mailman admin bar"',
         'bar-bounces:      "|/foo/bar/mail/mailman bounces bar"',
         'bar-confirm:      "|/foo/bar/mail/mailman confirm bar"',
         'bar-join:         "|/foo/bar/mail/mailman join bar"',
         'bar-leave:        "|/foo/bar/mail/mailman leave bar"',
         'bar-owner:        "|/foo/bar/mail/mailman owner bar"',
         'bar-request:      "|/foo/bar/mail/mailman request bar"',
         'bar-subscribe:    "|/foo/bar/mail/mailman subscribe bar"',
         'bar-unsubscribe:  "|/foo/bar/mail/mailman unsubscribe bar"']
      }
      let(:new_list_return) {
        prefix =<<EOF
To finish creating your mailing list, you must edit your /etc/aliases (or                           
equivalent) file by adding the following lines, and possibly running the                            
`newaliases' program:                                                                               
                                                                                                    
## bar mailing list                                                                                 
EOF
        prefix+new_aliases.join("\n")
      }

      it "should create the list" do
        subject.should_receive(:run_command).
          with("#{fake_root}/bin/newlist -q \"bar\" \"foo@bar.baz\" \"qux\" 2>&1", nil).
          and_return([new_list_return, process])
        subject.stub(:list_names).and_return([],['bar'])
        subject.create_list(:name => 'bar', :admin_email => 'foo@bar.baz',
                            :admin_password => 'qux')
      end

      it "should not rely on the aliases setup output" do
        # https://www.pivotaltracker.com/story/show/9422507
        subject.should_receive(:run_command).
          with("#{fake_root}/bin/newlist -q \"bar\" \"foo@bar.baz\" \"qux\" 2>&1", nil).
          and_return(["", process])
        subject.stub(:list_names).and_return([],['bar'])
        subject.create_list(:name => 'bar', :admin_email => 'foo@bar.baz',
                            :admin_password => 'qux')
      end

      it "should raise an exception if the list already exists" do
        # https://www.pivotaltracker.com/story/show/9421449
        subject.should_not_receive(:run_command).
          with("#{fake_root}/bin/newlist -q \"foo\" \"foo@bar.baz\" \"qux\" 2>&1", nil)
        subject.stub(:list_names).and_return(['foo'])
        lambda {
          subject.create_list(:name => 'foo', :admin_email => 'foo@bar.baz',
                              :admin_password => 'qux')
        }.should raise_error(MailManager::ListNameConflictError)
      end
    end
  end

  describe "#delete_list" do
    it "should delete the list" do
      subject.should_receive(:run_command).
        with("#{fake_root}/bin/rmlist \"foo\" 2>&1", nil).
        and_return(["Removing list info", process])
      subject.stub(:list_names).and_return(['foo'])
      subject.delete_list('foo')
    end

    it "should raise an exception if the list doesn't exist" do
      subject.stub(:list_names).and_return([])
      lambda {
        subject.delete_list('foo')
      }.should raise_error(MailManager::ListNotFoundError)
    end
  end

  context "with populated list" do
    let(:list) { list = mock(MailManager::List)
                 list.stub(:name).and_return('foo')
                 list }

    let(:regular_members) { ['me@here.com', 'you@there.org'] }
    let(:digest_members)  { ['them@that.net'] }

    let(:cmd) { "PYTHONPATH=#{File.expand_path('lib/mailmanager')} " +
                "/usr/bin/env python " +
                "#{fake_root}/bin/withlist -q -r listproxy.command \"foo\" " }

    describe "#regular_members" do
      it "should ask Mailman for the regular list members" do
        test_lib_method(:regular_members, :getRegularMemberKeys, regular_members)
      end
    end

    describe "#digest_members" do
      it "should ask Mailman for the digest list members" do
        test_lib_method(:digest_members, :getDigestMemberKeys, digest_members)
      end
    end

    describe "#add_member" do
      it "should ask Mailman to add the member to the list" do
        new_member = 'newb@dnc.org'
        test_lib_setter(:add_member, new_member)
      end
    end

    describe "#approved_add_member" do
      it "should ask Mailman to add the member to the list" do
        new_member = 'newb@dnc.org'
        test_lib_setter(:approved_add_member, new_member)
      end
    end

    describe "#delete_member" do
      it "should ask Mailman to delete the member from the list" do
        former_member = 'oldie@ofa.org'
        test_lib_setter(:delete_member, former_member)
      end
    end

    describe "#approved_delete_member" do
      it "should ask Mailman to delete the member from the list" do
        former_member = 'oldie@ofa.org'
        test_lib_setter(:approved_delete_member, former_member)
      end
    end

    describe "#moderators" do
      it "should ask Mailman for the list's moderators" do
        test_lib_method(:moderators, :moderator, ['phb@bigcorp.com', 'nhb@smallstartup.com'])
      end
    end

    describe "#add_moderator" do
      it "should ask Mailman to add the moderator to the list" do
        subject.should_receive(:moderators).with(list).and_return({'result' => 'success', 'return' => []})
        test_lib_method(:add_moderator, 'moderator.append', nil, 'foo@bar.com')
      end

      it "should raise ModeratorAlreadyExistsError if they already a moderator" do
        subject.should_receive(:moderators).with(list).and_return({'result' => 'success', 'return' => ['foo@bar.com']})
        lambda {
          subject.add_moderator(list, 'foo@bar.com')
        }.should raise_error(MailManager::ModeratorAlreadyExistsError)
      end
    end

    describe "#delete_moderator" do
      it "should ask Mailman to delete the moderator from the list" do
        subject.should_receive(:moderators).with(list).and_return({'result' => 'success', 'return' => ['foo@bar.com']})
        test_lib_method(:delete_moderator, 'moderator.remove', nil, 'foo@bar.com')
      end

      it "should raise ModeratorNotFoundError if they are not already a moderator" do
        subject.should_receive(:moderators).with(list).and_return({'result' => 'success', 'return' => ['other@bar.com']})
        lambda {
          subject.delete_moderator(list, 'foo@bar.com')
        }.should raise_error(MailManager::ModeratorNotFoundError)
      end
    end

    describe "#web_page_url" do
      it "should ask Mailman for the list's web address" do
        test_lib_attr(:web_page_url, "http://bar.com/mailman/listinfo/foo")
      end
    end

    describe "#request_email" do
      it "should ask Mailman for the request email address" do
        test_lib_getter(:request_email, "foo-request@bar.com")
      end
    end

    describe "#description" do
      it "should ask Mailman for the list's description" do
        test_lib_attr(:description, "this is a mailing list")
      end
    end

    describe "#subject_prefix" do
      it "should ask Mailman for the list's subject prefix" do
        test_lib_attr(:subject_prefix, "[Foo] ")
      end
    end
  end

  def test_lib_getter(lib_method, return_value, *args)
    cc_mailman_method = camel_case("get_#{lib_method.to_s}")
    test_lib_method(lib_method, cc_mailman_method, return_value, *args)
  end

  def test_lib_setter(lib_method, *args)
    cc_mailman_method = camel_case(lib_method.to_s)
    test_lib_method(lib_method, cc_mailman_method, nil, *args)
  end

  def test_lib_attr(lib_attr, return_value)
    test_lib_method(lib_attr, lib_attr, return_value)
  end

  def test_lib_method(lib_method, mailman_method, return_value=nil, *args)
    if return_value.is_a?(Hash)
      result = return_value
    else
      result = {"result" => "success"}
      result["return"] = return_value unless return_value.nil?
    end
    subject.should_receive(:run_command).
      with(cmd+"#{mailman_method.to_s} #{cmd_args(*args)}2>&1", nil).
      and_return([JSON.generate(result),process])
    subject.send(lib_method, list, *args).should == result
  end

  def camel_case(s)
    s.gsub(/^[a-z]|[\s_]+[a-z]/) { |a| a.upcase }.gsub(/[\s_]/, '')
  end

  def cmd_args(*args)
    arg_str = args.map { |a|
      MailManager::Lib::escape(a)
    }.join(' ')
    arg_str += ' ' if arg_str.length > 0
  end
end
