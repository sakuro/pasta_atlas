# frozen_string_literal: true

namespace :cleanup do
  desc "Delete expired guest generations and orphaned maps"
  task guest_maps: :environment do
    result = Hanami.app["operations.cleanup_guest_maps"].call
    if result.success?
      stats = result.value!
      puts "Deleted #{stats[:deleted_generations]} guest generation(s) and #{stats[:deleted_maps]} orphaned map(s)"
    else
      warn "Cleanup failed: #{result.failure}"
      exit 1
    end
  end
end
