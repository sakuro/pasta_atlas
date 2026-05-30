# frozen_string_literal: true

require "hanami/rake_tasks"

# Add your custom rake tasks to the lib/tasks directory
Rake.add_rakelib "lib/tasks"

require "rake/clean"
CLEAN.include("coverage", ".rspec_status", ".yardoc", "log/*.log*", "spec/examples.txt")
CLOBBER.include("doc/api", "public/assets", "public/assets.json")

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  raise unless ENV.fetch("HANAMI_ENV", "development") == "production"
end

begin
  require "yard"
  YARD::Rake::YardocTask.new(:doc)
rescue LoadError
  raise unless ENV.fetch("HANAMI_ENV", "development") == "production"
end

task default: %i[spec rubocop]
