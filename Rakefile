APP_ROOT = File.expand_path( File.dirname(__FILE__) )
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'mailmanager/version'
require 'rake'
require 'rake/rdoctask'
require 'rspec/core/rake_task'

# load all .rake files in the tasks dir
Dir["#{APP_ROOT}/tasks/**/*.rake"].each { |task| load task }

desc "Build gem locally"
task :build do
  system "gem build mailmanager.gemspec"
  FileUtils.mkdir_p "pkg"
  FileUtils.mv "mailmanager-#{MailManager::VERSION}.gem", "pkg"
end

desc "Install gem locally"
task :install => :build do
  system "gem install pkg/mailmanager-#{MailManager::VERSION}.gem"
end

desc "Push gem to gems.dnc.org"
task :inabox => :build do
  system "gem inabox pkg/mailmanager-#{MailManager::VERSION}.gem"
end

desc "Push gem to rubygems.org"
task :release => :build do
  system "gem push pkg/mailmanager-#{MailManager::VERSION}.gem"
end

desc "Generate rdoc html"
Rake::RDocTask.new do |rd|
  rd.main = "lib/mailmanager.rb"
  rd.rdoc_files.include("lib/**/*.rb")
end

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end
