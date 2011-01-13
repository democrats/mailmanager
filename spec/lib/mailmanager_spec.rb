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

        before :each do
          Dir.stub(:exist?).with(mailman_path).and_return(true)
          Dir.stub(:exist?).with("#{mailman_path}/bin").and_return(true)
          bin_files.each do |bf|
            File.stub(:exist?).with("#{mailman_path}/bin/#{bf}").and_return(true)
          end
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

        describe "#lists" do
          it "should return an array of existing mailing lists" do

          end
        end
      end
    end
  end

  describe "List" do
    describe ".initialize" do

    end

    describe ".create" do
      
    end
  end
end
