# frozen_string_literal: true

desc "Trigger deploy workflow via GitHub CLI"
task :deploy do
  sh "gh workflow run deploy.yml"
end
