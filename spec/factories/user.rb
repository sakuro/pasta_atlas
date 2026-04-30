# frozen_string_literal: true

Factory.define(:user) do |f|
  f.sequence(:name) {|n| "user%010d" % n }
end
