require 'spec_helper'

describe "MailManager" do

  describe "Base" do
    describe ".instance" do
      it "should require setting the Mailman root directory first" do
        lambda {
          MailManager::Base.instance
        }.should raise_error
      end

      it "should require that the Mailman directory exist" do
        lambda {
          MailManager.root = '/foo/bar'
          MailManager::Base.instance
        }.should raise_error
      end

      it "should require that the Mailman dir have a bin subdir" do
        Dir.stub(:exist?).with('/foo/bar').and_return(true)
        Dir.stub(:exist?).with('/foo/bar/bin').and_return(false)
        lambda {
          MailManager.root = '/foo/bar'
          MailManager::Base.instance
        }.should raise_error
      end

      context "with a valid Mailman dir" do
        let(:mailman_path) { '/usr/local/mailman' }
        let(:bin_files) { ['list_lists', 'newlist', 'inject'] }
        let(:subject) { MailManager::Base.instance }

        before :each do
          Dir.stub(:exist?).with(mailman_path).and_return(true)
          Dir.stub(:exist?).with("#{mailman_path}/bin").and_return(true)
          bin_files.each do |bf|
            File.stub(:exist?).with("#{mailman_path}/bin/#{bf}").and_return(true)
          end
        end

        after :each do
          # since subject is a singleton, side-effects of tests will leak unless
          # we destroy and re-create it every test
          subject = nil
        end

        it "should raise an error if one of the bin files is missing" do
          File.stub(:exist?).with("#{mailman_path}/bin/inject").and_return(false)
          lambda {
            MailManager.root = mailman_path
            MailManager::Base.instance
          }.should raise_error
        end

        it "should succeed if the all the bin files are present" do
          MailManager.root = mailman_path
          MailManager::Base.instance.should_not be_nil
        end

        describe "#python" do
          it "should return the python bin being used to run Mailman commands" do
            subject.python.should == '/usr/bin/env python'
          end
        end

        describe "#python=" do
          it "should set the python bin used to run Mailman commands" do
            subject.python = '/foo/bar/python'
            subject.python.should == '/foo/bar/python'
          end
        end

        describe "#lists" do
          it "should return an array of existing mailing lists" do
            # TODO
          end
        end
      end
    end
  end
end
