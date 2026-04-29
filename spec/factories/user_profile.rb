# frozen_string_literal: true

Factory.define(:user_profile) do |f|
  f.sequence(:name) {|n| "user%010d" % n }
  f.association(:user)
end
