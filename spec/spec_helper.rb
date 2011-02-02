$:.unshift File.expand_path('../lib', __FILE__)
if ENV['COVERAGE_REPORT']
  $:.unshift File.expand_path(File.dirname(__FILE__))
  require "mailmanager_simplecov"
  SimpleCov.start 'mailmanager'
end
require 'mailmanager'
