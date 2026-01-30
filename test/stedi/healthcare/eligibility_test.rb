# frozen_string_literal: true

require "test_helper"

class Stedi::Healthcare::EligibilityTest < Minitest::Test
  def setup
    super
    @client = Stedi::Client::Substitute.build
    @eligibility = Stedi::Healthcare::Eligibility.new(client: @client)
  end

  def request_params
    {
      trading_partner_service_id: "BCBSIL",
      provider: {
        npi: "1234567890",
        organization_name: "Example Medical Group"
      },
      subscriber: {
        member_id: "ABC123456",
        first_name: "Jane",
        last_name: "Doe",
        date_of_birth: "19800101"
      },
      encounter: {
        service_type_codes: ["30"]
      }
    }
  end

  def success_response
    {
      "controlNumber" => "123456789",
      "tradingPartnerServiceId" => "BCBSIL",
      "subscriber" => {
        "firstName" => "Jane",
        "lastName" => "Doe",
        "memberId" => "ABC123456",
        "dateOfBirth" => "19800101"
      },
      "planInformation" => {
        "planName" => "Open Access Plus",
        "groupNumber" => "GRP001"
      },
      "benefitsInformation" => [
        {
          "code" => "1",
          "name" => "Active Coverage",
          "benefitAmount" => "0.00"
        },
        {
          "code" => "30",
          "name" => "Health Benefit Plan Coverage",
          "benefitAmount" => "100.00"
        }
      ]
    }
  end

  def test_check_posts_to_eligibility_endpoint
    @client.response_body = success_response

    @eligibility.check(request_params)

    assert @client.posted?(path: "/change/medicalnetwork/eligibility/v3")
  end

  def test_check_sends_request_params_as_body
    @client.response_body = success_response

    @eligibility.check(request_params)

    assert_equal request_params, @client.last_post[:body]
  end

  def test_check_returns_response_object
    @client.response_body = success_response

    response = @eligibility.check(request_params)

    assert_instance_of Stedi::Response, response
  end

  def test_check_response_has_control_number
    @client.response_body = success_response

    response = @eligibility.check(request_params)

    assert_equal "123456789", response.control_number
  end

  def test_check_response_has_trading_partner_service_id
    @client.response_body = success_response

    response = @eligibility.check(request_params)

    assert_equal "BCBSIL", response.trading_partner_service_id
  end

  def test_check_response_supports_nested_dot_notation
    @client.response_body = success_response

    response = @eligibility.check(request_params)

    assert_equal "Jane", response.subscriber.first_name
    assert_equal "Doe", response.subscriber.last_name
    assert_equal "Open Access Plus", response.plan_information.plan_name
  end

  def test_check_response_supports_array_access
    @client.response_body = success_response

    response = @eligibility.check(request_params)

    assert_instance_of Array, response.benefits_information
    assert_equal 2, response.benefits_information.length
    assert_equal "1", response.benefits_information.first.code
    assert_equal "Active Coverage", response.benefits_information.first.name
  end

  def test_check_raises_authentication_error_for_401
    @client.response_status = 401
    @client.response_body = { "message" => "Invalid API key" }

    error = assert_raises(Stedi::AuthenticationError) do
      @eligibility.check(request_params)
    end

    assert_equal "Invalid API key", error.message
  end

  def test_check_raises_authentication_error_for_403
    @client.response_status = 403
    @client.response_body = { "message" => "Access denied" }

    error = assert_raises(Stedi::AuthenticationError) do
      @eligibility.check(request_params)
    end

    assert_equal "Access denied", error.message
  end

  def test_check_raises_validation_error_for_400
    @client.response_status = 400
    @client.response_body = {
      "message" => "Validation failed",
      "errors" => [
        { "field" => "subscriber.memberId", "message" => "is required" }
      ]
    }

    error = assert_raises(Stedi::ValidationError) do
      @eligibility.check(request_params)
    end

    assert_equal "Validation failed", error.message
    assert_instance_of Array, error.errors
    assert_equal "subscriber.memberId", error.errors.first["field"]
  end

  def test_check_raises_validation_error_for_422
    @client.response_status = 422
    @client.response_body = { "message" => "Validation failed" }

    error = assert_raises(Stedi::ValidationError) do
      @eligibility.check(request_params)
    end

    assert_equal "Validation failed", error.message
  end

  def test_check_raises_api_error_for_500
    @client.response_status = 500
    @client.response_body = { "message" => "Internal server error" }

    error = assert_raises(Stedi::ApiError) do
      @eligibility.check(request_params)
    end

    assert_equal "Internal server error", error.message
    assert_equal 500, error.status
  end
end
