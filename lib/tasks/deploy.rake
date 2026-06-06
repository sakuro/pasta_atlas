# frozen_string_literal: true

desc "Trigger deploy workflow via GitHub CLI"
task :deploy do
  sh "gh workflow run deploy.yml"
end

namespace :deploy do
  desc "Show the commit hash of the last successful deploy"
  task :latest_hash do
    sha = %x(gh run list --workflow=deploy.yml --status=success --limit=1 --json headSha --jq '.[0].headSha').strip
    puts sha
  end
end
