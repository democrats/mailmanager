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
        lib.stub(:regular_members_of).with(subject).and_return(regular_members)
        subject.regular_members.should == regular_members
      end
    end

    describe "#digest_members" do
      it "should return only digest members" do
        lib.stub(:digest_members_of).with(subject).and_return(digest_members)
        subject.digest_members.should == digest_members
      end
    end

    describe "#members" do
      it "should return the list of all members" do
        lib.stub(:regular_members_of).with(subject).and_return(regular_members)
        lib.stub(:digest_members_of).with(subject).and_return(digest_members)
        subject.members.should == all_members
      end
    end
  end

  describe "#add_member" do
    it "should add the member" do
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

  describe "#add_approved_member" do
    it "should add the member" do
      lib.should_receive(:add_approved_member).with(subject, 'foo@bar.baz').
        and_return({'result' => 'success'})
      subject.add_approved_member('foo@bar.baz').should == :success
    end

    it "should accept an optional name argument" do
      lib.should_receive(:add_approved_member).with(subject, 'Foo Bar <foo@bar.baz>').
        and_return({'result' => 'success'})
      subject.add_approved_member('foo@bar.baz', 'Foo Bar').should == :success
    end
  end
end
