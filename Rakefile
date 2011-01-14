$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'mailmanager/version'
require 'rake'
require 'rake/rdoctask'

desc "Build gem locally"
task :build do
  system "gem build mailmanager.gemspec"
  FileUtils.mkdir_p "pkg"
  FileUtils.mv "mailmanager-#{MailManager::VERSION}.gem", "pkg"
end

desc "Install gem locally"
task :install => :build do
  system "gem install pkg/mailmanager-#{MailManager::VERSION}"
end

#desc "Push gem to rubygems.org"
#task :release => :build do
  #system "gem push mailmanager-#{MailManager::VERSION}"
#end

Rake::RDocTask.new do |rd|
  rd.main = "lib/mailmanager.rb"
  rd.rdoc_files.include("lib/**/*.rb")
end
