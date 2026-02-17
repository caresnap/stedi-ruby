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

  def test_healthcare_returns_healthcare_client
    assert_instance_of Stedi::Healthcare::Client, Stedi.healthcare
  end

  def test_healthcare_memoizes_client
    client1 = Stedi.healthcare
    client2 = Stedi.healthcare

    assert_same client1, client2
  end

  def test_core_returns_core_client
    assert_instance_of Stedi::Core::Client, Stedi.core
  end

  def test_core_memoizes_client
    client1 = Stedi.core
    client2 = Stedi.core

    assert_same client1, client2
  end

  def test_reset_clears_all_configuration
    Stedi.api_key = "test_key"
    healthcare = Stedi.healthcare
    core = Stedi.core

    Stedi.reset!

    assert_nil Stedi.api_key
    refute_same healthcare, Stedi.healthcare
    refute_same core, Stedi.core
  end

  def test_service_api_urls_are_constants
    assert_equal "https://healthcare.us.stedi.com/2024-04-01", Stedi::Healthcare::API_URL
    assert_equal "https://core.us.stedi.com/2023-08-01", Stedi::Core::API_URL
  end

  def test_version_is_defined
    assert_equal "0.2.0", Stedi::VERSION
  end
end
