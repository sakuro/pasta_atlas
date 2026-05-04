# frozen_string_literal: true

Factory.define(:user_preference) do |f|
  f.timezone "UTC"
  f.association(:user)
end
