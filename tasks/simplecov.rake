$:.unshift File.expand_path('../spec', __FILE__)
require 'mailmanager_simplecov'

namespace :simplecov do
  task :start do
    SimpleCov.start 'mailmanager'
  end
end
