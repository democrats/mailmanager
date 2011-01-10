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

  describe "#members" do
    it "should return the list of members" do

    end
  end
end
