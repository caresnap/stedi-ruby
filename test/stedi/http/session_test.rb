# frozen_string_literal: true

require "test_helper"

class Stedi::HTTP::SessionTest < Minitest::Test
  RequestOptions = Struct.new(:timeout)
  Request = Struct.new(:params, :body, :headers, :options)
  RawResponse = Struct.new(:status, :body)

  class ConnectionSubstitute
    attr_reader :requests
    attr_accessor :next_response
    attr_reader :headers

    def initialize
      @requests = []
      @next_response = RawResponse.new(200, "{}")
      @headers = {}
    end

    def get(path)
      request = Request.new(nil, nil, {}, RequestOptions.new)
      yield request if block_given?
      @requests << {
        method: :get,
        path: path,
        params: request.params,
        body: request.body,
        headers: request.headers,
        timeout: request.options.timeout
      }
      next_response
    end

    def post(path)
      request = Request.new(nil, nil, {}, RequestOptions.new)
      yield request if block_given?
      @requests << {
        method: :post,
        path: path,
        params: request.params,
        body: request.body,
        headers: request.headers,
        timeout: request.options.timeout
      }
      next_response
    end
  end

  Receiver = Struct.new(:http_session)

  def test_call_get_builds_path_and_camelizes_query_params
    connection = ConnectionSubstitute.new
    connection.next_response = RawResponse.new(200, '{"ok":true}')

    session = Stedi::HTTP::Session.build(
      api_key: "token",
      api_url: "https://api.example.com/v1",
      connection: connection
    )

    response = session.(:get, "/polling/transactions", params: { start_date_time: "2026-02-11T00:00:00Z" })

    assert_equal true, response.ok
    assert_equal "/v1/polling/transactions", connection.requests.last[:path]
    assert_equal({ "startDateTime" => "2026-02-11T00:00:00Z" }, connection.requests.last[:params])
  end

  def test_call_post_camelizes_request_body
    connection = ConnectionSubstitute.new
    connection.next_response = RawResponse.new(200, '{"controlNumber":"123"}')

    session = Stedi::HTTP::Session.build(
      api_key: "token",
      api_url: "https://api.example.com/v1",
      connection: connection
    )

    response = session.(:post, "/eligibility", body: { subscriber: { first_name: "Jane" } })

    assert_equal "123", response.control_number
    assert_equal({ "subscriber" => { "firstName" => "Jane" } }.to_json, connection.requests.last[:body])
  end

  def test_call_applies_request_headers
    connection = ConnectionSubstitute.new
    connection.next_response = RawResponse.new(200, '{"ok":true}')

    session = Stedi::HTTP::Session.build(
      api_key: "token",
      api_url: "https://api.example.com/v1",
      connection: connection
    )

    response = session.(
      :get,
      "/polling/transactions",
      headers: {
        x_forwarded_for: "203.0.113.10, 198.51.100.7",
        "Accept-Encoding" => "gzip"
      }
    )

    assert_equal true, response.ok
    assert_equal "203.0.113.10, 198.51.100.7", connection.requests.last[:headers]["X-Forwarded-For"]
    assert_equal "gzip", connection.requests.last[:headers]["Accept-Encoding"]
  end

  def test_call_applies_request_timeout
    connection = ConnectionSubstitute.new
    connection.next_response = RawResponse.new(200, '{"ok":true}')

    session = Stedi::HTTP::Session.build(
      api_key: "token",
      api_url: "https://api.example.com/v1",
      connection: connection
    )

    response = session.(:get, "/polling/transactions", timeout: 120)

    assert_equal true, response.ok
    assert_equal 120, connection.requests.last[:timeout]
  end

  def test_call_logs_full_request_details
    connection = ConnectionSubstitute.new
    connection.next_response = RawResponse.new(200, '{"ok":true}')

    session = Stedi::HTTP::Session.build(
      api_key: "token",
      api_url: "https://api.example.com/v1",
      connection: connection
    )
    connection.headers["Authorization"] = "token"
    connection.headers["Content-Type"] = "application/json"
    connection.headers["Accept"] = "application/json"

    logger = Log::Substitute.build
    logger.level = :trace
    session.logger = logger

    session.(
      :post,
      "/eligibility",
      params: { page_size: 5 },
      body: { subscriber: { first_name: "Jane" } },
      headers: { "X-Test" => "1" }
    )

    request_log = logger.telemetry_sink.logged_records.map(&:data).find do |record|
      record.message.start_with?("HTTP request details:")
    end

    refute_nil request_log
    assert_includes request_log.message, 'method: :post'
    assert_includes request_log.message, 'https://api.example.com/v1/eligibility'
    assert_includes request_log.message, '"Authorization" => "token"'
    assert_includes request_log.message, '"X-Test" => "1"'
    assert_includes request_log.message, '"pageSize" => 5'
    assert_includes request_log.message, '"subscriber" => {"firstName" => "Jane"}'
  end

  def test_call_raises_authentication_error_for_401
    connection = ConnectionSubstitute.new
    connection.next_response = RawResponse.new(401, '{"message":"Invalid API key"}')

    session = Stedi::HTTP::Session.build(
      api_key: "token",
      api_url: "https://api.example.com/v1",
      connection: connection
    )

    error = assert_raises(Stedi::AuthenticationError) do
      session.(:get, "/secure")
    end

    assert_equal "Invalid API key", error.message
  end

  def test_call_raises_validation_error_for_400
    connection = ConnectionSubstitute.new
    connection.next_response = RawResponse.new(400, '{"message":"Validation failed","errors":[{"field":"startDateTime"}]}')

    session = Stedi::HTTP::Session.build(
      api_key: "token",
      api_url: "https://api.example.com/v1",
      connection: connection
    )

    error = assert_raises(Stedi::ValidationError) do
      session.(:get, "/polling/transactions")
    end

    assert_equal "Validation failed", error.message
    assert_equal "startDateTime", error.errors.first["field"]
  end

  def test_call_raises_api_error_for_500
    connection = ConnectionSubstitute.new
    connection.next_response = RawResponse.new(500, '{"message":"Internal error"}')

    session = Stedi::HTTP::Session.build(
      api_key: "token",
      api_url: "https://api.example.com/v1",
      connection: connection
    )

    error = assert_raises(Stedi::ApiError) do
      session.(:get, "/fail")
    end

    assert_equal "Internal error", error.message
    assert_equal 500, error.status
  end

  def test_class_configure_assigns_instance
    receiver = Receiver.new

    Stedi::HTTP::Session.configure(receiver, api_key: "token", api_url: "https://api.example.com")

    assert_instance_of Stedi::HTTP::Session, receiver.http_session
  end

  def test_class_call_executes_with_built_instance
    connection = ConnectionSubstitute.new
    connection.next_response = RawResponse.new(200, '{"ok":true}')

    response = Stedi::HTTP::Session.call(
      :get,
      "/health",
      api_key: "token",
      api_url: "https://api.example.com/v1",
      connection: connection
    )

    assert_equal true, response.ok
  end

  def test_substitute_records_calls
    substitute = Stedi::HTTP::Session::Substitute.build
    substitute.response = Stedi::Response.new({ "ok" => true })

    response = substitute.(:get, "/x", params: { a: 1 }, headers: { "X-Test" => "1" }, timeout: 120)

    assert_equal true, response.ok
    assert_equal :get, substitute.calls.last[:method]
    assert_equal "/x", substitute.calls.last[:path]
    assert_equal({ a: 1 }, substitute.calls.last[:params])
    assert_equal({ "X-Test" => "1" }, substitute.calls.last[:headers])
    assert_equal 120, substitute.calls.last[:timeout]
  end
end
