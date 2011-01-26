if ENV['RUBY_ENV'] == 'test'

  namespace :hudson do
    task :spec => ["hudson:setup:rspec", 'rake:spec']

    namespace :setup do
      task :pre_ci do
        ENV["CI_REPORTS"] = 'results/rspec/'
        gem 'ci_reporter'
        require 'ci/reporter/rake/rspec'
      end
      task :rspec => [:pre_ci, "ci:setup:rspec"]
    end
  end
end
