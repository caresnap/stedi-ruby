# frozen_string_literal: true

require "test_helper"

class Stedi::ResponseTest < Minitest::Test
  def test_converts_camel_case_keys_to_snake_case
    response = Stedi::Response.new({ "firstName" => "Jane", "lastName" => "Doe" })

    assert_equal "Jane", response.first_name
    assert_equal "Doe", response.last_name
  end

  def test_handles_nested_hashes
    response = Stedi::Response.new({
      "subscriber" => {
        "firstName" => "Jane",
        "memberId" => "ABC123"
      }
    })

    assert_instance_of Stedi::Response, response.subscriber
    assert_equal "Jane", response.subscriber.first_name
    assert_equal "ABC123", response.subscriber.member_id
  end

  def test_handles_arrays_of_hashes
    response = Stedi::Response.new({
      "benefits" => [
        { "code" => "1", "benefitAmount" => "100.00" },
        { "code" => "2", "benefitAmount" => "200.00" }
      ]
    })

    assert_instance_of Array, response.benefits
    assert_equal 2, response.benefits.length
    assert_instance_of Stedi::Response, response.benefits.first
    assert_equal "100.00", response.benefits.first.benefit_amount
  end

  def test_handles_arrays_of_primitives
    response = Stedi::Response.new({
      "serviceCodes" => ["30", "31", "32"]
    })

    assert_equal ["30", "31", "32"], response.service_codes
  end

  def test_bracket_access_with_string_keys
    response = Stedi::Response.new({ "firstName" => "Jane" })

    assert_equal "Jane", response["first_name"]
  end

  def test_bracket_access_with_symbol_keys
    response = Stedi::Response.new({ "firstName" => "Jane" })

    assert_equal "Jane", response[:first_name]
  end

  def test_to_h_converts_response_to_hash
    response = Stedi::Response.new({
      "firstName" => "Jane",
      "subscriber" => { "memberId" => "ABC123" }
    })

    hash = response.to_h

    assert_instance_of Hash, hash
    assert_equal "Jane", hash["first_name"]
    assert_instance_of Hash, hash["subscriber"]
    assert_equal "ABC123", hash["subscriber"]["member_id"]
  end

  def test_respond_to_returns_true_for_existing_keys
    response = Stedi::Response.new({ "firstName" => "Jane" })

    assert response.respond_to?(:first_name)
  end

  def test_respond_to_returns_false_for_non_existing_keys
    response = Stedi::Response.new({ "firstName" => "Jane" })

    refute response.respond_to?(:last_name)
  end

  def test_inspect_returns_readable_representation
    response = Stedi::Response.new({ "firstName" => "Jane", "lastName" => "Doe" })

    assert_equal "#<Stedi::Response first_name, last_name>", response.inspect
  end
end
