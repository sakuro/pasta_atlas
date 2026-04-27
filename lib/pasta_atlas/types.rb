# frozen_string_literal: true

require "dry/types"

module PastaAtlas
  Types = Dry.Types(default: :strict)
  public_constant :Types

  module Types
    # Define your custom types here
  end
end
