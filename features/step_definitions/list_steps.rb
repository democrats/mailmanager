Given /^I have a list named "([^"]*)"$/ do |list_name|
  Given %{no lists exist}
  When %{I create a new list "#{list_name}"}
end

When /^I create a new list "([^"]*)"$/ do |list_name|
  @list = @mailmanager.create_list(:name => list_name, :admin_email => 'cuke@foo.org', :admin_password => 'greenisgood')
end

When /^I delete list "([^"]*)"$/ do |list_name|
  list = @mailmanager.get_list(list_name)
  list.delete
end

When /^I ask for its (.+)$/ do |attr|
  @attr = @list.send(attr)
end

Then /^I should get a URL$/ do
  @attr.should =~ %r{^http://.*/}
end

