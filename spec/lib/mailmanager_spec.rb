describe "MailManager" do
  describe "List" do
    describe ".initialize" do
      it "should require a Mailman directory" do
        lambda {
          subject.new
        }.should raise_error(ArgumentError)
      end
    end

    describe ".create" do

    end
  end
end
