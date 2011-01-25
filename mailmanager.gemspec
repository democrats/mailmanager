# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'mailmanager/version'

spec = Gem::Specification.new do |s|
  s.name = 'mailmanager'
  s.version = MailManager::VERSION
  s.summary = "GNU Mailman wrapper for Ruby"
  s.description = %{Ruby wrapper library for GNU Mailman's admin functions}
  s.files = Dir['lib/**/*.rb'] + Dir['lib/**/*.py'] + Dir['spec/**/*.rb'] + %w(Changelog LICENSE README.rdoc)
  s.require_path = 'lib'
  s.has_rdoc = true
  s.author = "Wes Morgan"
  s.email = "MorganW@dnc.org"
  s.homepage = "http://github.com/dnclabs/mailmanager"
  s.add_dependency('json', '~>1.4.6')
  s.add_dependency('open4', '~>1.0.1')
  s.add_development_dependency('rspec', '~>2.4.0')
  s.add_development_dependency('ZenTest', '~>4.4.2')
  s.add_development_dependency('ruby-debug19')
end
