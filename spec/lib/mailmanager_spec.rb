require 'spec_helper'

describe "MailManager" do

  describe "Base" do
    describe ".initialize" do
      it "should require a Mailman directory argument" do
        lambda {
          MailManager::Base.new
        }.should raise_error(ArgumentError)
      end

      it "should require that the Mailman directory exist" do
        lambda {
          MailManager::Base.new('/foo/bar')
        }.should raise_error(ArgumentError)
      end

      it "should require that the Mailman dir have a bin subdir" do
        Dir.stub(:exist?).with('/foo/bar').and_return(true)
        Dir.stub(:exist?).with('/foo/bar/bin').and_return(false)
        lambda {
          MailManager::Base.new('/foo/bar')
        }.should raise_error(ArgumentError)
      end

      context "with a valid Mailman dir" do
        let(:mailman_path) { '/usr/local/mailman' }
        let(:bin_files) { ['add_members', 'remove_members', 'list_lists',
                          'list_members', 'newlist', 'rmlist', 'sync_members'] }

        before :each do
          Dir.stub(:exist?).with(mailman_path).and_return(true)
          Dir.stub(:exist?).with("#{mailman_path}/bin").and_return(true)
          bin_files.each do |bf|
            File.stub(:exist?).with("#{mailman_path}/bin/#{bf}").and_return(true)
          end
        end

        it "should raise an error if one of the bin files is missing" do
          File.stub(:exist?).with("#{mailman_path}/bin/add_members").and_return(false)
          lambda {
            MailManager::Base.new(mailman_path)
          }.should raise_error(ArgumentError)
        end

        it "should succeed if the all the bin files are present" do
          MailManager::Base.new(mailman_path).should_not be_nil
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
