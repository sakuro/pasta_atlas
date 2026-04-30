# frozen_string_literal: true

require "hanami/rake_tasks"

# Add your custom rake tasks to the lib/tasks directory
Rake.add_rakelib "lib/tasks"

require "rake/clean"
CLEAN.include("coverage", ".rspec_status", ".yardoc")
CLOBBER.include("doc/api")

require "rubocop/rake_task"
RuboCop::RakeTask.new

require "yard"
YARD::Rake::YardocTask.new(:doc)

task default: %i[spec rubocop]
