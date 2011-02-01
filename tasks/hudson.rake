if ENV['RUBY_ENV'] == 'test' || ENV['RUBY_ENV'] == 'cucumber'

  require 'cucumber/rake/task'

  namespace :hudson do
    def report_path
      "results/features"
    end

    Cucumber::Rake::Task.new({'cucumber' => [:report_setup]}) do |t|
      t.cucumber_opts = %{--profile default --no-color --format junit --out #{report_path}}
    end

    task :report_setup do
      rm_rf report_path
      mkdir_p report_path
    end

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
