# frozen_string_literal: true

require "test_helper"

class Stedi::Healthcare::ReportsTest < Minitest::Test
  class PollingSubstitute
    attr_reader :calls

    def initialize(response)
      @response = response
      @calls = []
    end

    def transactions(start_date_time: nil, page_token: nil, page_size: nil)
      @calls << {
        start_date_time: start_date_time,
        page_token: page_token,
        page_size: page_size
      }
      @response
    end
  end

  class FailOnSecondGetClient
    attr_reader :gets

    def initialize
      @gets = []
    end

    def get(path, _params = {})
      @gets << { path: path }

      if @gets.length == 2
        raise Stedi::ApiError.new("second fetch failed", status: 500)
      end

      Stedi::Response.new({
        "meta" => { "transactionId" => "report-#{@gets.length}" },
        "transactions" => []
      })
    end
  end

  def setup
    super
    @client = Stedi::Client::Substitute.build
    @client.response_body = {
      "meta" => { "transactionId" => "report-1" },
      "transactions" => []
    }
    @polling = PollingSubstitute.new(polling_response)
    @reports = Stedi::Healthcare::Reports.new(client: @client, polling: @polling)
  end

  def test_get_835_gets_report_endpoint
    @reports.get_835(transaction_id: "txn-123")

    assert @client.got?(path: "/change/medicalnetwork/reports/v2/txn-123/835")
  end

  def test_poll_835_filters_to_inbound_835_transactions
    @reports.poll_835(start_date_time: "2026-02-11T00:00:00Z")

    paths = @client.gets.map { |get| get[:path] }

    assert_equal(
      [
        "/change/medicalnetwork/reports/v2/inbound-835-succeeded/835",
        "/change/medicalnetwork/reports/v2/inbound-835-failed/835"
      ],
      paths
    )
  end

  def test_poll_835_includes_non_succeeded_inbound_835_transactions
    result = @reports.poll_835(start_date_time: "2026-02-11T00:00:00Z")

    transaction_ids = result.transactions.map { |transaction| transaction.transaction_id }

    assert_equal ["inbound-835-succeeded", "inbound-835-failed"], transaction_ids
  end

  def test_poll_835_returns_structured_response
    result = @reports.poll_835(start_date_time: "2026-02-11T00:00:00Z")

    assert_instance_of Stedi::Response, result
    assert_instance_of Array, result.transactions
    assert_instance_of Array, result.reports
    assert_equal "next-page-token", result.next_page_token
  end

  def test_poll_835_passes_polling_params
    @reports.poll_835(
      start_date_time: "2026-02-11T00:00:00Z",
      page_size: 25
    )

    assert_equal(
      {
        start_date_time: "2026-02-11T00:00:00Z",
        page_token: nil,
        page_size: 25
      },
      @polling.calls.first
    )
  end

  def test_poll_835_fails_fast_when_report_fetch_fails
    polling = PollingSubstitute.new(
      Stedi::Response.new({
        "items" => [
          inbound_835_transaction("first"),
          inbound_835_transaction("second"),
          inbound_835_transaction("third")
        ]
      })
    )
    client = FailOnSecondGetClient.new
    reports = Stedi::Healthcare::Reports.new(client: client, polling: polling)

    error = assert_raises(Stedi::ApiError) do
      reports.poll_835(start_date_time: "2026-02-11T00:00:00Z")
    end

    assert_equal "second fetch failed", error.message
    assert_equal 2, client.gets.length
  end

  private

  def polling_response
    Stedi::Response.new({
      "items" => [
        inbound_835_transaction("inbound-835-succeeded"),
        inbound_835_transaction("inbound-835-failed", status: "failed"),
        inbound_277_transaction("inbound-277"),
        outbound_835_transaction("outbound-835")
      ],
      "nextPageToken" => "next-page-token"
    })
  end

  def inbound_835_transaction(id, status: "succeeded")
    {
      "direction" => "INBOUND",
      "status" => status,
      "transactionId" => id,
      "x12" => {
        "metadata" => {
          "transaction" => {
            "transactionSetIdentifier" => "835"
          }
        }
      }
    }
  end

  def inbound_277_transaction(id)
    {
      "direction" => "INBOUND",
      "status" => "succeeded",
      "transactionId" => id,
      "x12" => {
        "metadata" => {
          "transaction" => {
            "transactionSetIdentifier" => "277"
          }
        }
      }
    }
  end

  def outbound_835_transaction(id)
    {
      "direction" => "OUTBOUND",
      "status" => "succeeded",
      "transactionId" => id,
      "x12" => {
        "metadata" => {
          "transaction" => {
            "transactionSetIdentifier" => "835"
          }
        }
      }
    }
  end
end
