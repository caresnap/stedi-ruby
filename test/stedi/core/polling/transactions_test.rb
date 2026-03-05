# frozen_string_literal: true

require "test_helper"
require "date"

class Stedi::Core::Polling::TransactionsTest < Minitest::Test
  Receiver = Struct.new(:poll_transactions)

  def setup
    super
    @session = Stedi::Core::Session::Substitute.build
    @session.response = Stedi::Response.new({ "items" => [] })
    @transactions = Stedi::Core::Polling::Transactions.build(session: @session)
  end

  def test_call_polls_transactions_endpoint
    @transactions.("2026-02-11T00:00:00Z")

    assert_equal :get, @session.calls.last[:method]
    assert_equal "/polling/transactions", @session.calls.last[:path]
  end

  def test_call_sends_query_params
    @transactions.("2026-02-11T00:00:00Z", page_size: 50)

    assert_equal(
      {
        start_date_time: "2026-02-11T00:00:00Z",
        page_size: 50
      },
      @session.calls.last[:params]
    )
  end

  def test_call_accepts_page_token_without_start_date_time
    @transactions.(nil, page_token: "next-page")

    assert_equal({ page_token: "next-page" }, @session.calls.last[:params])
  end

  def test_call_serializes_time_to_iso8601
    timestamp = Time.utc(2026, 2, 11, 12, 30, 15)

    @transactions.(timestamp)

    assert_equal timestamp.iso8601, @session.calls.last[:params][:start_date_time]
  end

  def test_call_serializes_datetime_to_iso8601
    timestamp = DateTime.new(2026, 2, 11, 12, 30, 15, "+00:00")

    @transactions.(timestamp)

    assert_equal timestamp.iso8601, @session.calls.last[:params][:start_date_time]
  end

  def test_call_raises_when_start_date_time_and_page_token_missing
    error = assert_raises(ArgumentError) do
      @transactions.()
    end

    assert_equal "Provide either start_date_time or page_token", error.message
  end

  def test_class_configure_assigns_instance
    receiver = Receiver.new

    Stedi::Core::Polling::Transactions.configure(receiver)

    assert_instance_of Stedi::Core::Polling::Transactions, receiver.poll_transactions
  end

  def test_class_call_runs_with_injected_session
    response = Stedi::Core::Polling::Transactions.call(
      "2026-02-11T00:00:00Z",
      session: @session
    )

    assert_instance_of Stedi::Response, response
  end

  def test_substitute_records_calls
    substitute = Stedi::Core::Polling::Transactions::Substitute.build

    substitute.("2026-02-11T00:00:00Z", page_size: 10)

    assert_equal "2026-02-11T00:00:00Z", substitute.calls.last[:start_date_time]
    assert_equal 10, substitute.calls.last[:page_size]
  end
end
