# frozen_string_literal: true

require "json"

desc "Trigger deploy workflow via GitHub CLI"
task :deploy do
  head_sha = %x(git rev-parse HEAD).strip
  ci = JSON.parse(%x(gh run list --workflow=ci.yml --limit=1 --json headSha,status,conclusion)).first

  if ci["headSha"] != head_sha
    abort "CI has not run for current HEAD (#{head_sha[0, 7]}). Latest CI was for #{ci["headSha"][0, 7]}."
  end

  if ci["status"] != "completed"
    abort "CI is still #{ci["status"]} for #{head_sha[0, 7]}."
  end

  if ci["conclusion"] != "success"
    abort "CI #{ci["conclusion"]} for #{head_sha[0, 7]}. Deploy aborted."
  end

  sh "gh workflow run deploy.yml"
end

namespace :deploy do
  desc "Show the commit hash of the last successful deploy"
  task :latest_hash do
    sha = %x(gh run list --workflow=deploy.yml --status=success --limit=1 --json headSha --jq '.[0].headSha').strip
    puts sha
  end
end
