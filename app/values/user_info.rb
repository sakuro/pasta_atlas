# frozen_string_literal: true

module PastaAtlas
  module Values
    # Aggregates display-oriented user data assembled from User and UserProfile for use in view layer.
    UserInfo = Data.define(:name, :display_name, :avatar_url)
  end
end
