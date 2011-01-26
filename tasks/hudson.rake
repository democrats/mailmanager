if Rails.env =='test'

  namespace :hudson do
    task :spec => ["hudson:setup:rspec", 'db:migrate', 'rake:spec']

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
