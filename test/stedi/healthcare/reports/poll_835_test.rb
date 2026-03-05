# frozen_string_literal: true

require "test_helper"

class Stedi::Healthcare::Reports::Poll835Test < Minitest::Test
  Receiver = Struct.new(:poll_835)

  def setup
    super
    @poll_transactions = Stedi::Core::Polling::Transactions::Substitute.build
    @get_835 = Stedi::Healthcare::Reports::Get835::Substitute.build
    @poll_835 = Stedi::Healthcare::Reports::Poll835.build(
      poll_transactions: @poll_transactions,
      get_835: @get_835
    )
  end

  def test_call_filters_inbound_835_and_fetches_reports
    @poll_transactions.response = Stedi::Response.new(
      {
        "items" => [
          inbound_transaction("inbound-835-succeeded", transaction_set_identifier: "835", status: "succeeded"),
          inbound_transaction("inbound-835-failed", transaction_set_identifier: "835", status: "failed"),
          inbound_transaction("inbound-277", transaction_set_identifier: "277", status: "succeeded"),
          outbound_transaction("outbound-835", transaction_set_identifier: "835", status: "succeeded")
        ],
        "nextPageToken" => "next-page-token"
      }
    )

    @get_835.response_proc = lambda do |transaction_id, _index|
      Stedi::Response.new(
        {
          "meta" => { "transactionId" => transaction_id },
          "transactions" => []
        }
      )
    end

    response = @poll_835.("2026-02-11T00:00:00Z", page_size: 25)

    assert_equal 2, response.transactions.length
    assert_equal "inbound-835-succeeded", response.transactions.first.transaction_id
    assert_equal "inbound-835-failed", response.transactions.last.transaction_id
    assert_equal 2, response.reports.length
    assert_equal "next-page-token", response.next_page_token

    assert_equal "inbound-835-succeeded", @get_835.calls.first[:transaction_id]
    assert_equal "inbound-835-failed", @get_835.calls.last[:transaction_id]
  end

  def test_call_fails_fast_if_get_835_raises
    @poll_transactions.response = Stedi::Response.new(
      {
        "items" => [
          inbound_transaction("first", transaction_set_identifier: "835", status: "succeeded"),
          inbound_transaction("second", transaction_set_identifier: "835", status: "failed"),
          inbound_transaction("third", transaction_set_identifier: "835", status: "succeeded")
        ]
      }
    )

    @get_835.response_proc = lambda do |_transaction_id, index|
      raise Stedi::ApiError.new("boom", status: 500) if index == 2

      Stedi::Response.new({ "meta" => { "transactionId" => "ok" }, "transactions" => [] })
    end

    assert_raises(Stedi::ApiError) do
      @poll_835.("2026-02-11T00:00:00Z")
    end

    assert_equal 2, @get_835.calls.length
  end

  def test_class_configure_assigns_instance
    receiver = Receiver.new

    Stedi::Healthcare::Reports::Poll835.configure(receiver)

    assert_instance_of Stedi::Healthcare::Reports::Poll835, receiver.poll_835
  end

  def test_class_call_runs_with_injected_dependencies
    @poll_transactions.response = Stedi::Response.new({ "items" => [], "nextPageToken" => nil })

    response = Stedi::Healthcare::Reports::Poll835.call(
      "2026-02-11T00:00:00Z",
      poll_transactions: @poll_transactions,
      get_835: @get_835
    )

    assert_instance_of Stedi::Response, response
    assert_equal [], response.transactions
    assert_equal [], response.reports
  end

  def test_substitute_records_calls
    substitute = Stedi::Healthcare::Reports::Poll835::Substitute.build

    substitute.("2026-02-11T00:00:00Z", page_size: 10)

    assert_equal "2026-02-11T00:00:00Z", substitute.calls.last[:start_date_time]
    assert_equal 10, substitute.calls.last[:page_size]
  end

  private

  def inbound_transaction(id, transaction_set_identifier:, status:)
    {
      "transactionId" => id,
      "direction" => "INBOUND",
      "status" => status,
      "x12" => {
        "metadata" => {
          "transaction" => {
            "transactionSetIdentifier" => transaction_set_identifier
          }
        }
      }
    }
  end

  def outbound_transaction(id, transaction_set_identifier:, status:)
    {
      "transactionId" => id,
      "direction" => "OUTBOUND",
      "status" => status,
      "x12" => {
        "metadata" => {
          "transaction" => {
            "transactionSetIdentifier" => transaction_set_identifier
          }
        }
      }
    }
  end
end
