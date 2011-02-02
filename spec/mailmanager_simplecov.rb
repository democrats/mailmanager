require 'simplecov'
require 'simplecov-rcov'

class SimpleCov::Formatter::MergedFormatter
  def format(result)
    SimpleCov::Formatter::HTMLFormatter.new.format(result)
    SimpleCov::Formatter::RcovFormatter.new.format(result)
  end
end

SimpleCov.adapters.define 'mailmanager' do
  add_filter '/spec/'
  add_filter '/features/'
  add_filter '/config/'
  add_filter '/html/'
  add_filter '/mailman/'
  add_filter '/pkg/'
  add_filter '/tasks/'
  add_filter '/results/'

  add_group 'Gem', 'lib/'
end
SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
