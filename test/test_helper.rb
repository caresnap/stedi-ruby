# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "stedi"
require "minitest/autorun"

class Minitest::Test
  def setup
    Stedi.reset!
    Stedi.api_key = "test_api_key"
  end
end
