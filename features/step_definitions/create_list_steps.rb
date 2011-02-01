When /^I create a new list "([^"]*)"$/ do |list_name|
  @mailmanager.create_list(:name => list_name, :admin_email => 'cuke@foo.org', :admin_password => 'greenisgood')
end

