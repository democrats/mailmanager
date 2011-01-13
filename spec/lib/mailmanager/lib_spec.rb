require 'spec_helper'

describe MailManager::Lib do
  let(:mailmanager) { mock(MailManager) }
  let(:subject)     { MailManager::Lib.new }
  let(:fake_root)   { '/foo/bar' }

  before :each do
    subject.stub(:mailmanager).and_return(mailmanager)
    mailmanager.stub(:root).and_return(fake_root)
  end

  describe "#lists" do
    it "should return all existing lists" do
      list_result = <<EOF 
3 matching mailing lists found:
        Foo - [no description available]
     BarBar - Dummy list
    Mailman - Mailman site list
EOF
      subject.stub(:run_command).with("#{fake_root}/bin/list_lists 2>&1").
        and_return(list_result)
      subject.lists.should have(3).lists
    end
  end

  describe "#create_list" do
    it "should raise an argument error if list name is missing" do
      lambda {
        subject.create_list(:admin_email => 'foo@bar.baz', :admin_password => 'qux')
      }.should raise_error(ArgumentError)
    end
    it "should raise an argument error if list admin email is missing" do
      lambda {
        subject.create_list(:name => 'foo', :admin_password => 'qux')
      }.should raise_error(ArgumentError)
    end
    it "should raise an argument error if admin password is missing" do
      lambda {
        subject.create_list(:name => 'foo', :admin_email => 'foo@bar.baz')
      }.should raise_error(ArgumentError)
    end

    context "with valid list params" do
      let(:new_aliases) {
        ['foo:              "|/foo/bar/mail/mailman post foo"',
         'foo-admin:        "|/foo/bar/mail/mailman admin foo"',
         'foo-bounces:      "|/foo/bar/mail/mailman bounces foo"',
         'foo-confirm:      "|/foo/bar/mail/mailman confirm foo"',
         'foo-join:         "|/foo/bar/mail/mailman join foo"',
         'foo-leave:        "|/foo/bar/mail/mailman leave foo"',
         'foo-owner:        "|/foo/bar/mail/mailman owner foo"',
         'foo-request:      "|/foo/bar/mail/mailman request foo"',
         'foo-subscribe:    "|/foo/bar/mail/mailman subscribe foo"',
         'foo-unsubscribe:  "|/foo/bar/mail/mailman unsubscribe foo"']
      }
      let(:new_list_return) {
        prefix =<<EOF
To finish creating your mailing list, you must edit your /etc/aliases (or                           
equivalent) file by adding the following lines, and possibly running the                            
`newaliases' program:                                                                               
                                                                                                    
## foo mailing list                                                                                 
EOF
        prefix+new_aliases.join("\n")
      }
      let(:fake_aliases_file) { mock(File) }

      before :each do
        File.stub(:open).with('/etc/aliases', 'a').and_return(fake_aliases_file)
        subject.stub(:run_newaliases_command)
      end

      it "should create the list" do
        subject.should_receive(:run_command).
          with("#{fake_root}/bin/newlist -q \"foo\" \"foo@bar.baz\" \"qux\" 2>&1").
          and_return(new_list_return)
        subject.create_list(:name => 'foo', :admin_email => 'foo@bar.baz',
                            :admin_password => 'qux')
      end
    end
  end

  context "with populated list" do
    let(:list) { list = mock(MailManager::List)
                 list.stub(:name).and_return('foo')
                 list }

    let(:regular_members) { ['me@here.com', 'you@there.org'] }
    let(:digest_members)  { ['them@that.net'] }

    let(:cmd) { "PYTHONPATH=#{File.expand_path('lib/mailmanager')} " +
                "#{fake_root}/bin/withlist " }
    let(:read_args)  { "-q -r listproxy.command \"foo\" " }
    let(:write_args) { "-l " + read_args }

    describe "#regular_members_of" do
      it "should retrieve the regular list members" do
        subject.should_receive(:run_command).
          with(cmd+read_args+"getRegularMemberKeys 2>&1").
          and_return(JSON.generate(regular_members))
        subject.regular_members_of(list).should == regular_members
      end
    end

    describe "#digest_members_of" do
      it "should retrieve the digest list members" do
        subject.should_receive(:run_command).
          with(cmd+read_args+"getDigestMemberKeys 2>&1").
          and_return(JSON.generate(digest_members))
        subject.digest_members_of(list).should == digest_members
      end
    end

    describe "#add_member" do
      it "should add the member to the list" do
        new_member = 'newb@dnc.org'
        result = {"result" => "pending_confirmation"}
        subject.should_receive(:run_command).
          with(cmd+write_args+"AddMember \"#{new_member}\" 2>&1").
          and_return(JSON.generate(result))
        subject.add_member(list, new_member).should == result
      end
    end

    describe "#add_approved_member" do
      it "should add the member to the list" do
        new_member = 'newb@dnc.org'
        result = {"result" => "success"}
        subject.should_receive(:run_command).
          with(cmd+write_args+"ApprovedAddMember \"#{new_member}\" 2>&1").
          and_return(JSON.generate(result))
        subject.add_approved_member(list, new_member).should == result
      end
    end
  end

end
