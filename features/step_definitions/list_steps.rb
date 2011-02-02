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

Then /^I should get an email address$/ do
  # super basic email regex
  @attr.should =~ %r{^[^@]+@[^\.]+\..+}
end

When /^I add a moderator "([^"]*)"$/ do |mod|
  @list.add_moderator(mod)
end

Then /^I should have (\d+) moderators?$/ do |num|
  @list.should have(num.to_i).moderators
end

When /^I delete a moderator "([^"]*)"$/ do |mod|
  @list.delete_moderator(mod)
end

Given /^I set its (.+?) to "([^"]*)"$/ do |attr,val|
  @list.send("#{attr}=",val)
end

Then /^I should get "([^"]*)"$/ do |val|
  @attr.should == val
end

