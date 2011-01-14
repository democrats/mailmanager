spec = Gem::Specification.new do |s|
  s.name = 'mailmanager'
  s.version = '1.0.7'
  s.summary = "GNU Mailman wrapper for Ruby"
  s.description = %{Ruby wrapper library for GNU Mailman's admin functions}
  s.files = Dir['lib/**/*.rb'] + Dir['lib/**/*.py'] + Dir['spec/**/*.rb']
  s.require_path = 'lib'
  s.has_rdoc = false
  s.author = "Wes Morgan"
  s.email = "MorganW@dnc.org"
  s.homepage = "http://github.com/dnclabs/mailmanager"
  s.add_dependency('json', '~>1.4.6')
  s.add_dependency('open4', '~>1.0.1')
end
