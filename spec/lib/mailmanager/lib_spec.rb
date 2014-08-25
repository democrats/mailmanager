require 'spec_helper'

describe MailManager::Lib do
  let(:mailmanager) { mock(MailManager) }
  let(:subject)     { MailManager::Lib.new }
  let(:fake_root)   { '/foo/bar' }
  let(:python)      { '/usr/bin/env python' }
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
      subject.stub(:run_command).with("#{python} #{fake_root}/bin/list_lists 2>&1", nil).
        and_return([list_result, process])
      subject.lists.should have(3).lists
    end
  end

  describe "#create_list" do
    before :each do
      subject.stub(:run_command).with("#{python} #{fake_root}/bin/list_lists 2>&1", nil).
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
          with("#{python} #{fake_root}/bin/newlist -q \"bar\" \"foo@bar.baz\" \"qux\" 2>&1", nil).
          and_return([new_list_return, process])
        subject.stub(:list_names).and_return([],['bar'])
        subject.create_list(:name => 'bar', :admin_email => 'foo@bar.baz',
                            :admin_password => 'qux')
      end

      it "should not rely on the aliases setup output" do
        # https://www.pivotaltracker.com/story/show/9422507
        subject.should_receive(:run_command).
          with("#{python} #{fake_root}/bin/newlist -q \"bar\" \"foo@bar.baz\" \"qux\" 2>&1", nil).
          and_return(["", process])
        subject.stub(:list_names).and_return([],['bar'])
        subject.create_list(:name => 'bar', :admin_email => 'foo@bar.baz',
                            :admin_password => 'qux')
      end

      it "should raise an exception if the list already exists" do
        # https://www.pivotaltracker.com/story/show/9421449
        subject.should_not_receive(:run_command).
          with("#{python} #{fake_root}/bin/newlist -q \"foo\" \"foo@bar.baz\" \"qux\" 2>&1", nil)
        subject.stub(:list_names).and_return(['foo'])
        lambda {
          subject.create_list(:name => 'foo', :admin_email => 'foo@bar.baz',
                              :admin_password => 'qux')
        }.should raise_error(MailManager::ListNameConflictError)
      end

      it "should raise a MailmanExecuteError if the list creation fails on the Mailman side" do
        subject.should_receive(:run_command).
          with("#{python} #{fake_root}/bin/newlist -q \"bar\" \"foo@bar.baz\" \"qux\" 2>&1", nil).
          and_return(["", process])
        subject.stub(:get_list).and_raise(MailManager::ListNotFoundError)
        lambda {
          subject.create_list(:name => 'bar', :admin_email => 'foo@bar.baz',
                              :admin_password => 'qux')
        }.should raise_error(MailManager::MailmanExecuteError)
      end
    end
  end

  describe "#delete_list" do
    it "should delete the list" do
      subject.should_receive(:run_command).
        with("#{python} #{fake_root}/bin/rmlist \"foo\" 2>&1", nil).
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

    describe "#inject" do
      it "should tell Mailman to inject a message into the list" do
        test_message = <<EOF
From: "Morgan, Wesley" <MorganW@dnc.org>
To: "labs@mailman-dev.dnc.org" <labs@mailman-dev.dnc.org>
Sender: "labs-bounces@mailman-dev.dnc.org" <labs-bounces@mailman-dev.dnc.org>
Content-Class: urn:content-classes:message
Date: Tue, 18 Jan 2011 13:26:59 -0500
Subject: [Labs] is this thing on?
Thread-Topic: is this thing on?
Thread-Index: Acu3PUssIxkW+1TESgmnlPvaBgroVQ==
Message-ID: <C3DA7B38-E1F9-4331-9025-D066DA7376F2@dnc.org>
List-Help: <mailto:labs-request@mailman-dev.dnc.org?subject=help>
List-Subscribe: <http://mailman-dev.dnc.org/mailman/listinfo/labs>,
	<mailto:labs-request@mailman-dev.dnc.org?subject=subscribe>
List-Unsubscribe: <http://mailman-dev.dnc.org/mailman/options/labs>,
	<mailto:labs-request@mailman-dev.dnc.org?subject=unsubscribe>
Accept-Language: en-US
Content-Language: en-US
X-Auto-Response-Suppress: All
acceptlanguage: en-US
Content-Type: text/plain; charset="us-ascii"
Content-Transfer-Encoding: quoted-printable
MIME-Version: 1.0

Cello?
_______________________________________________
Labs mailing list
Labs@mailman-dev.dnc.org
http://mailman-dev.dnc.org/mailman/listinfo/labs

EOF
        test_message = "message!"
        test_mailman_cmd(:inject, :inject, nil, nil, test_message)
      end
    end

    describe "#regular_members" do
      it "should ask Mailman for the regular list members" do
        test_withlist_cmd(:regular_members, :getRegularMemberKeys, regular_members)
      end
    end

    describe "#digest_members" do
      it "should ask Mailman for the digest list members" do
        test_withlist_cmd(:digest_members, :getDigestMemberKeys, digest_members)
      end
    end

    describe "#add_member" do
      it "should ask Mailman to add the member to the list" do
        new_member = 'newb@dnc.org'
        test_method_setter(:add_member, new_member)
      end
    end

    describe "#approved_add_member" do
      it "should ask Mailman to add the member to the list" do
        new_member = 'newb@dnc.org'
        test_method_setter(:approved_add_member, new_member)
      end
    end

    describe "#delete_member" do
      it "should ask Mailman to delete the member from the list" do
        former_member = 'oldie@ofa.org'
        test_method_setter(:delete_member, former_member)
      end
    end

    describe "#approved_delete_member" do
      it "should ask Mailman to delete the member from the list" do
        former_member = 'oldie@ofa.org'
        test_method_setter(:approved_delete_member, former_member)
      end
    end

    describe "#moderators" do
      it "should ask Mailman for the list's moderators" do
        test_withlist_cmd(:moderators, :moderator, ['phb@bigcorp.com', 'nhb@smallstartup.com'])
      end
    end

    describe "#add_moderator" do
      it "should ask Mailman to add the moderator to the list" do
        subject.should_receive(:moderators).with(list).and_return({'result' => 'success', 'return' => []})
        test_withlist_cmd(:add_moderator, 'moderator.append', nil, 'foo@bar.com')
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
        test_withlist_cmd(:delete_moderator, 'moderator.remove', nil, 'foo@bar.com')
      end

      it "should raise ModeratorNotFoundError if they are not already a moderator" do
        subject.should_receive(:moderators).with(list).and_return({'result' => 'success', 'return' => ['other@bar.com']})
        lambda {
          subject.delete_moderator(list, 'foo@bar.com')
        }.should raise_error(MailManager::ModeratorNotFoundError)
      end
    end

    describe "#find_member" do
      context "with string as argument" do
        it "should ask Mailman for the matching lists" do
          subject.should_receive(:run_command).
            with(/python.*find_member.*foo/, nil).and_return([<<-EOF, process])
foo@example.com found in:
     list1
     list2
     foobar
foo@example.net found in:
     list3
            EOF

          result = subject.find_member('foo@bar.com')
          result.should be_a(Hash)
          result.keys.first.should eq('foo@example.com')
          result.values.first.should eq(['list1', 'list2', 'foobar'])
          result.values.last.should eq(['list3'])
        end
      end

      context "with Regexp as argument" do
        it "raises an ArgumentError" do
          lambda {
            subject.find_member(/^member/)
          }.should raise_error(ArgumentError, /Python/)
        end
      end
    end

    describe "#web_page_url" do
      it "should ask Mailman for the list's web address" do
        test_attr_getter(:web_page_url, "http://bar.com/mailman/listinfo/foo")
      end
    end

    describe "#request_email" do
      it "should ask Mailman for the request email address" do
        test_method_getter(:request_email, "foo-request@bar.com")
      end
    end

    describe "#description" do
      it "should ask Mailman for the list's description" do
        test_attr_getter(:description, "this is a mailing list")
      end
    end

    describe "#subject_prefix" do
      it "should ask Mailman for the list's subject prefix" do
        test_attr_getter(:subject_prefix, "[Foo] ")
      end
    end

    describe "#host_name" do
      it "should ask Mailman for the list's host name" do
        test_attr_getter(:host_name, "groups.foo.org")
      end
    end

    describe "#set_host_name" do
      it "should tell Mailman to set the list's host name" do
        test_attr_setter(:host_name, 'groups.foo.org')
      end
    end
  end

  def test_method_getter(lib_method, return_value, *args)
    cc_mailman_method = camel_case("get_#{lib_method.to_s}")
    test_withlist_cmd(lib_method, cc_mailman_method, return_value, *args)
  end

  def test_method_setter(lib_method, *args)
    cc_mailman_method = camel_case(lib_method.to_s)
    test_withlist_cmd(lib_method, cc_mailman_method, nil, *args)
  end

  def test_attr_getter(attr, return_value)
    test_withlist_cmd(attr, attr, return_value)
  end

  def test_attr_setter(attr, *args)
    test_withlist_cmd("set_#{attr}", attr, nil, *args)
  end

  def test_withlist_cmd(lib_method, mailman_method, return_value=nil, *args)
    test_mailman_cmd(lib_method, :withlist, mailman_method, return_value=nil, *args)
  end

  def test_mailman_cmd(lib_method, mailman_cmd, mailman_sub_cmd, return_value=nil, *args)
    command =  "/usr/bin/env python " +
               "#{fake_root}/bin/#{mailman_cmd.to_s} "
    command += "--listname=" if mailman_cmd.to_sym == :inject
    if mailman_cmd.to_sym == :withlist
      command =  "PYTHONPATH=#{File.expand_path('lib/mailmanager')} #{command}"
      command += "-q -r listproxy.command "
    end
    command += "\"foo\" "
    if return_value.is_a?(Hash)
      result = return_value
    else
      result = {"result" => "success"}
      result["return"] = return_value unless return_value.nil?
    end
    cmd_arg = command
    cmd_arg += "#{mailman_sub_cmd.to_s} " unless mailman_sub_cmd.nil?
    cmd_arg += "#{cmd_args(*args)}" unless mailman_cmd.to_sym == :inject
    cmd_arg += "2>&1"
    stdin_arg = mailman_cmd.to_sym == :inject ? args[0] : nil
    subject.should_receive(:run_command).
      with(cmd_arg, stdin_arg).and_return([JSON.generate(result),process])
      # with(mailman_cmd+"#{mailman_method.to_s} #{cmd_args(*args)}2>&1", nil).
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
