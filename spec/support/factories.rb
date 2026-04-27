# frozen_string_literal: true

require "rom-factory"

Factory = ROM::Factory.configure {|config|
  config.rom = Hanami.app["db.rom"]
}

Dir[File.join(__dir__, "..", "factories", "*.rb")].each {|f| require f }

RSpec.configure do |config|
  config.before { ROM::Factory::Sequences.instance.reset }
end
