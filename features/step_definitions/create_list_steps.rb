Given /^MailManager is initialized on "([^\"]+)"$/ do |mailman_root|
  @mailmanager = MailManager.init(mailman_root)
end

Given /^no lists exist$/ do
  @mailmanager.list_names.each do |list_name|
    @mailmanager.delete_list(list_name)
  end
end

When /^I create a new list "([^"]*)"$/ do |list_name|
  @mailmanager.create_list(:name => list_name, :admin_email => 'cuke@foo.org', :admin_password => 'greenisgood')
end

Then /^I should have a list named "([^"]*)"$/ do |list_name|
  @mailmanager.list_names.should include(list_name)
end

