require 'spec_helper'

describe MailManager::Lib do
  let(:mailman) { mock(MailManager) }
  let(:subject) { MailManager::Lib.new(mailman) }

  describe "#initialize" do
    it "should fail w/o a valid MailManager object" do
      lambda {
        MailManager::Lib.new
      }.should raise_error(ArgumentError)
    end

    context "with a valid MailManager object" do
      it "should succeed" do
        MailManager::Lib.new(mailman).should_not be_nil
      end
    end
  end

  describe "#lists" do
    it "should return all existing lists" do
      list_result = <<EOF 
3 matching mailing lists found:
        Foo - [no description available]
     BarBar - Dummy list
    Mailman - Mailman site list
EOF
      fake_root = '/foo/bar'
      mailman.stub(:root).and_return(fake_root)
      subject.stub(:run_command).with("#{fake_root}/bin/list_lists  2>&1").and_return(list_result)
      $?.stub(:exitstatus).and_return(0)
      subject.lists.should have(3).lists
    end
  end
end
