Given /^MailManager is initialized on "([^\"]+)"$/ do |mailman_root|
  @mailmanager = MailManager.init(mailman_root)
end

Given /^no lists exist$/ do
  @mailmanager.list_names.each do |list_name|
    @mailmanager.delete_list(list_name)
  end
end

Then /^it should raise (.+?) when (.+)$/ do |exception,when_step|
  lambda {
    When when_step
  }.should raise_error(eval(exception))
end

Then /^I should have (\d+) lists?$/ do |num|
  @mailmanager.should have(num.to_i).lists
end

Then /^I should have a list named "([^"]*)"$/ do |list_name|
  @mailmanager.list_names.should include(list_name)
end

