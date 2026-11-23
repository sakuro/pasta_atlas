# frozen_string_literal: true

require "hanami/rake_tasks"

# Add your custom rake tasks to the lib/tasks directory
Rake.add_rakelib "lib/tasks"

begin
  require "yard"
  YARD::Rake::YardocTask.new(:doc)
rescue LoadError
  raise unless ENV.fetch("HANAMI_ENV", "development") == "production"
end
