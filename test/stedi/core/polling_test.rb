# frozen_string_literal: true

require "test_helper"
require "date"

class Stedi::Core::PollingTest < Minitest::Test
  def setup
    super
    @client = Stedi::Client::Substitute.build
    @polling = Stedi::Core::Polling.new(client: @client)
    @client.response_body = { "items" => [] }
  end

  def test_transactions_gets_polling_endpoint
    @polling.transactions(start_date_time: "2026-02-11T12:00:00Z")

    assert @client.got?(path: "/polling/transactions")
  end

  def test_transactions_sends_query_params
    @polling.transactions(
      start_date_time: "2026-02-11T12:00:00Z",
      page_size: 50
    )

    assert_equal(
      { start_date_time: "2026-02-11T12:00:00Z", page_size: 50 },
      @client.last_get[:params]
    )
  end

  def test_transactions_supports_page_token_only
    @polling.transactions(page_token: "next-page")

    assert_equal({ page_token: "next-page" }, @client.last_get[:params])
  end

  def test_transactions_serializes_time_input_to_iso8601
    start_time = Time.utc(2026, 2, 11, 12, 30, 15)

    @polling.transactions(start_date_time: start_time)

    assert_equal start_time.iso8601, @client.last_get[:params][:start_date_time]
  end

  def test_transactions_serializes_datetime_input_to_iso8601
    start_date_time = DateTime.new(2026, 2, 11, 12, 30, 15, "+00:00")

    @polling.transactions(start_date_time: start_date_time)

    assert_equal start_date_time.iso8601, @client.last_get[:params][:start_date_time]
  end

  def test_transactions_raises_when_missing_required_parameters
    error = assert_raises(ArgumentError) do
      @polling.transactions
    end

    assert_equal "Provide either start_date_time or page_token", error.message
  end
end
