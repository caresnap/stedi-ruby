# frozen_string_literal: true

require "test_helper"

class StediTest < Minitest::Test
  def test_configure_yields_self
    Stedi.configure do |config|
      config.api_key = "my_api_key"
    end

    assert_equal "my_api_key", Stedi.api_key
  end

  def test_api_key_can_be_set_and_retrieved
    Stedi.api_key = "test_key"

    assert_equal "test_key", Stedi.api_key
  end

  def test_reset_clears_configuration
    Stedi.api_key = "test_key"

    Stedi.reset!

    assert_nil Stedi.api_key
  end

  def test_service_api_urls_are_constants
    assert_equal "https://healthcare.us.stedi.com/2024-04-01", Stedi::Healthcare::API_URL
    assert_equal "https://core.us.stedi.com/2023-08-01", Stedi::Core::API_URL
  end

  def test_version_is_defined
    assert_equal "0.2.0", Stedi::VERSION
  end
end
