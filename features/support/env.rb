$LOAD_PATH.unshift File.expand_path('../../lib', File.dirname(__FILE__))
if ENV['COVERAGE_REPORT']
  $LOAD_PATH.unshift File.expand_path('../../spec', File.dirname(__FILE__))
  require "mailmanager_simplecov"
  SimpleCov.start 'mailmanager'
end
require "mailmanager"
