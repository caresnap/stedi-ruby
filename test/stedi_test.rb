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

  def test_base_url_has_default_value
    Stedi.reset!

    assert_equal "https://healthcare.us.stedi.com/2024-04-01", Stedi.base_url
  end

  def test_base_url_can_be_overridden
    Stedi.base_url = "https://custom.api.com"

    assert_equal "https://custom.api.com", Stedi.base_url
  end

  def test_healthcare_returns_healthcare_client
    assert_instance_of Stedi::Healthcare::Client, Stedi.healthcare
  end

  def test_healthcare_memoizes_client
    client1 = Stedi.healthcare
    client2 = Stedi.healthcare

    assert_same client1, client2
  end

  def test_reset_clears_all_configuration
    Stedi.api_key = "test_key"
    Stedi.base_url = "https://custom.api.com"
    Stedi.healthcare

    Stedi.reset!

    assert_nil Stedi.api_key
    assert_equal "https://healthcare.us.stedi.com/2024-04-01", Stedi.base_url
  end

  def test_version_is_defined
    assert_equal "0.1.0", Stedi::VERSION
  end
end
