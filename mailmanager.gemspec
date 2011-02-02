# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'mailmanager/version'

spec = Gem::Specification.new do |s|
  s.name = 'mailmanager'
  s.version = MailManager::VERSION
  s.date = Time.now.utc.strftime("%Y-%m-%d")
  s.summary = "GNU Mailman wrapper for Ruby"
  s.description = %{Ruby wrapper library for GNU Mailman's admin functions}
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files spec`.split("\n")
  s.require_paths = ['lib']
  s.has_rdoc = true
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.rdoc_options = ["--charset=UTF-8"]
  s.authors = ["Wes Morgan"]
  s.email = "MorganW@dnc.org"
  s.homepage = "http://github.com/dnclabs/mailmanager"
  s.add_runtime_dependency('json', '~>1.4.6')
  s.add_runtime_dependency('open4', '~>1.0.1')
  s.add_development_dependency('rspec', '~>2.4.0')
  s.add_development_dependency('ZenTest', '~>4.4.2')
  s.add_development_dependency('ruby-debug19')
  s.add_development_dependency('ci_reporter')
  s.add_development_dependency('cucumber')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('simplecov-rcov')
end
