# frozen_string_literal: true

require "test_helper"

class Stedi::ClientTest < Minitest::Test
  def test_camelize_converts_snake_case_to_camel_case
    client = Stedi::Client.new
    result = client.send(:camelize, "first_name")

    assert_equal "firstName", result
  end

  def test_camelize_handles_multiple_underscores
    client = Stedi::Client.new
    result = client.send(:camelize, "date_of_birth")

    assert_equal "dateOfBirth", result
  end

  def test_camelize_keys_converts_hash_keys
    client = Stedi::Client.new
    input = { first_name: "Jane", last_name: "Doe" }

    result = client.send(:camelize_keys, input)

    assert_equal({ "firstName" => "Jane", "lastName" => "Doe" }, result)
  end

  def test_camelize_keys_handles_nested_hashes
    client = Stedi::Client.new
    input = {
      subscriber: {
        first_name: "Jane",
        date_of_birth: "19800101"
      }
    }

    result = client.send(:camelize_keys, input)

    expected = {
      "subscriber" => {
        "firstName" => "Jane",
        "dateOfBirth" => "19800101"
      }
    }
    assert_equal expected, result
  end

  def test_camelize_keys_handles_arrays
    client = Stedi::Client.new
    input = {
      items: [
        { item_name: "one" },
        { item_name: "two" }
      ]
    }

    result = client.send(:camelize_keys, input)

    expected = {
      "items" => [
        { "itemName" => "one" },
        { "itemName" => "two" }
      ]
    }
    assert_equal expected, result
  end

  def test_build_path_joins_api_url_path_with_request_path
    client = Stedi::Client.new(api_url: "https://api.example.com/v1")

    result = client.send(:build_path, "/users")

    assert_equal "/v1/users", result
  end

  def test_build_path_handles_path_without_leading_slash
    client = Stedi::Client.new(api_url: "https://api.example.com/v1")

    result = client.send(:build_path, "users")

    assert_equal "/v1/users", result
  end

  def test_build_path_handles_api_url_with_trailing_slash
    client = Stedi::Client.new(api_url: "https://api.example.com/v1/")

    result = client.send(:build_path, "/users")

    assert_equal "/v1/users", result
  end
end

class Stedi::Client::SubstituteTest < Minitest::Test
  def test_substitute_records_gets
    client = Stedi::Client::Substitute.build

    client.get("/test", { first_name: "Jane" })

    assert client.got?
    assert_equal "/test", client.last_get[:path]
    assert_equal({ first_name: "Jane" }, client.last_get[:params])
  end

  def test_substitute_records_posts
    client = Stedi::Client::Substitute.build

    client.post("/test", { name: "Jane" })

    assert client.posted?
    assert_equal "/test", client.last_post[:path]
    assert_equal({ name: "Jane" }, client.last_post[:body])
  end

  def test_substitute_returns_response_on_success
    client = Stedi::Client::Substitute.build
    client.response_body = { "result" => "success" }

    result = client.get("/test", {})

    assert_instance_of Stedi::Response, result
    assert_equal "success", result.result
  end

  def test_substitute_raises_authentication_error_for_401
    client = Stedi::Client::Substitute.build
    client.response_status = 401
    client.response_body = { "message" => "Invalid API key" }

    error = assert_raises(Stedi::AuthenticationError) do
      client.post("/test", {})
    end

    assert_equal "Invalid API key", error.message
  end

  def test_substitute_raises_authentication_error_for_403
    client = Stedi::Client::Substitute.build
    client.response_status = 403
    client.response_body = { "message" => "Access denied" }

    error = assert_raises(Stedi::AuthenticationError) do
      client.post("/test", {})
    end

    assert_equal "Access denied", error.message
  end

  def test_substitute_raises_validation_error_for_400
    client = Stedi::Client::Substitute.build
    client.response_status = 400
    client.response_body = {
      "message" => "Validation failed",
      "errors" => [{ "field" => "name", "message" => "is required" }]
    }

    error = assert_raises(Stedi::ValidationError) do
      client.post("/test", {})
    end

    assert_equal "Validation failed", error.message
    assert_equal "name", error.errors.first["field"]
  end

  def test_substitute_raises_validation_error_for_422
    client = Stedi::Client::Substitute.build
    client.response_status = 422
    client.response_body = { "message" => "Unprocessable entity" }

    error = assert_raises(Stedi::ValidationError) do
      client.post("/test", {})
    end

    assert_equal "Unprocessable entity", error.message
  end

  def test_substitute_raises_api_error_for_500
    client = Stedi::Client::Substitute.build
    client.response_status = 500
    client.response_body = { "message" => "Internal server error" }

    error = assert_raises(Stedi::ApiError) do
      client.get("/test", {})
    end

    assert_equal "Internal server error", error.message
    assert_equal 500, error.status
  end

  def test_got_with_path_filter
    client = Stedi::Client::Substitute.build
    client.get("/users", {})
    client.get("/orders", {})

    assert client.got?(path: "/users")
    assert client.got?(path: "/orders")
    refute client.got?(path: "/products")
  end

  def test_got_with_params_filter
    client = Stedi::Client::Substitute.build
    client.get("/test", { name: "Jane" })

    assert client.got?(params: { name: "Jane" })
    refute client.got?(params: { name: "John" })
  end

  def test_posted_with_path_filter
    client = Stedi::Client::Substitute.build
    client.post("/users", {})
    client.post("/orders", {})

    assert client.posted?(path: "/users")
    assert client.posted?(path: "/orders")
    refute client.posted?(path: "/products")
  end

  def test_posted_with_body_filter
    client = Stedi::Client::Substitute.build
    client.post("/test", { name: "Jane" })

    assert client.posted?(body: { name: "Jane" })
    refute client.posted?(body: { name: "John" })
  end
end
