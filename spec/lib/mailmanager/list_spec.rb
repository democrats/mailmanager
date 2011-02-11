require 'spec_helper'

describe MailManager::List do
  let(:lib)       { mock(MailManager::Lib) }
  let(:subject)   { MailManager::List.new('foo') }

  before :each do
    MailManager::List.stub(:lib).and_return(lib)
  end

  describe ".create" do
    it "should require the params arg" do
      lambda {
        MailManager::List.create
      }.should raise_error(ArgumentError)
    end

    it "should return the new list" do
      params = {:name => 'foo', :admin_email => 'foo@bar.baz', :admin_password => 'qux'}
      lib.stub(:create_list).with(params).and_return(subject)
      new_list = MailManager::List.create(params)
      new_list.should_not be_nil
      new_list.name.should == 'foo'
    end
  end

  describe "#initialize" do
    it "should take a name parameter" do
      MailManager::List.new('foo').name.should == 'foo'
    end

    it "should raise an error if the name arg is missing" do
      lambda {
        MailManager::List.new
      }.should raise_error(ArgumentError)
    end
  end

  describe "#to_s" do
    it "should return its name" do
      subject.to_s.should == "foo"
    end
  end

  context "with list members" do
    let(:regular_members) { ['me@here.com', 'you@there.org'] }
    let(:digest_members)  { ['them@that.net'] }
    let(:all_members)     { regular_members + digest_members }

    describe "#regular_members" do
      it "should return only regular members" do
        lib.stub(:regular_members).with(subject).and_return({'return' => regular_members})
        subject.regular_members.should == regular_members
      end
    end

    describe "#digest_members" do
      it "should return only digest members" do
        lib.stub(:digest_members).with(subject).and_return({'return' => digest_members})
        subject.digest_members.should == digest_members
      end
    end

    describe "#members" do
      it "should return the list of all members" do
        lib.stub(:regular_members).with(subject).and_return({'return' => regular_members})
        lib.stub(:digest_members).with(subject).and_return({'return' => digest_members})
        subject.members.should == all_members
      end
    end
  end

  describe "#add_member" do
    it "should tell lib to add the member" do
      lib.should_receive(:add_member).with(subject, 'foo@bar.baz').
        and_return({'result' => 'pending_confirmation'})
      subject.add_member('foo@bar.baz').should == :pending_confirmation
    end

    it "should accept an optional name argument" do
      lib.should_receive(:add_member).with(subject, 'Foo Bar <foo@bar.baz>').
        and_return({'result' => 'pending_confirmation'})
      subject.add_member('foo@bar.baz', 'Foo Bar').should == :pending_confirmation
    end
  end

  describe "#approved_add_member" do
    it "should tell lib to add the member" do
      lib.should_receive(:approved_add_member).with(subject, 'foo@bar.baz').
        and_return({'result' => 'success'})
      subject.approved_add_member('foo@bar.baz').should == :success
    end

    it "should accept an optional name argument" do
      lib.should_receive(:approved_add_member).with(subject, 'Foo Bar <foo@bar.baz>').
        and_return({'result' => 'success'})
      subject.approved_add_member('foo@bar.baz', 'Foo Bar').should == :success
    end
  end

  describe "#delete_member" do
    it "should tell lib to delete the member" do
      lib.should_receive(:delete_member).with(subject, 'foo@bar.baz').
        and_return({'result' => 'success'})
      subject.delete_member('foo@bar.baz').should == :success
    end
  end

  describe "#approved_delete_member" do
    it "should tell lib to delete the member" do
      lib.should_receive(:approved_delete_member).with(subject, 'foo@bar.baz').
        and_return({'result' => 'success'})
      subject.approved_delete_member('foo@bar.baz').should == :success
    end
  end

  context "when injecting a message" do
    let(:from)             { 'Foo Bar <foo@bar.name>' }
    let(:to)               { 'list@foo.org' }
    let(:subj)             { 'Test Subject' }
    let(:message)          { 'Test Message' }
    let(:headers)          { {'X-Custom-1' => 'foo', 'X-Custom-2' => 'bar'} }
    let(:raw_message_pre)  { <<EOF
From: #{from}
To: #{to}
Subject: #{subj}
EOF
    }
    let(:raw_message)      { raw_message_pre + "\n#{message}" }
    let(:msg_with_headers) {
      headers_arr = []
      headers.each_pair { |hdr, val|
        headers_arr << "#{hdr}: #{val}"
      }
      raw_message_pre + headers_arr.join("\n") + "\n#{message}"
    }

    describe "#inject" do
      it "should tell lib to inject a message into the list" do
        lib.stub(:list_address).with(subject).and_return({'result' => 'success', 'return' => to})
        lib.should_receive(:inject).with(subject, raw_message).
          and_return({'result' => 'success'})
        subject.inject(from, subj, message)
      end

      it "should accept custom headers" do
        lib.stub(:list_address).with(subject).and_return({'result' => 'success', 'return' => to})
        lib.should_receive(:inject).with(subject, msg_with_headers).
          and_return({'result' => 'success'})
        subject.inject(from, subj, message, headers)
      end
    end

    describe "#inject_raw" do
      it "should tell lib to inject whatever you send it" do
        lib.should_receive(:inject).with(subject, raw_message).
          and_return({'result' => 'success'})
        subject.inject_raw(raw_message)
      end
    end
  end

  context "host_name accessors" do
    let(:host_name) { 'groups.foo.org' }

    describe "#host_name=" do
      it "should tell lib to set the host_name" do
        lib.should_receive(:set_host_name).with(subject, host_name).
          and_return({'result' => 'success'})
        subject.host_name = host_name
      end
    end

    describe "#host_name" do
      it "should ask lib for the host_name" do
        lib.should_receive(:host_name).with(subject).
          and_return({'result' => 'success', 'return' => host_name})
        subject.host_name.should == host_name
      end
    end
  end
end
