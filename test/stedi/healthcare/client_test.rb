# frozen_string_literal: true

require "test_helper"

class Stedi::Healthcare::ClientTest < Minitest::Test
  class CoreClientSubstitute
    attr_reader :polling

    def initialize(polling)
      @polling = polling
    end
  end

  class PollingSubstitute
    def transactions(**_)
      Stedi::Response.new({ "items" => [] })
    end
  end

  def setup
    super
    @client = Stedi::Client::Substitute.build
    @client.response_body = { "meta" => { "transactionId" => "tx" }, "transactions" => [] }
    core_client = CoreClientSubstitute.new(PollingSubstitute.new)
    @healthcare = Stedi::Healthcare::Client.new(client: @client, core_client: core_client)
  end

  def test_eligibility_uses_shared_client
    @healthcare.eligibility.check({ trading_partner_service_id: "BCBSIL" })

    assert @client.posted?(path: "/change/medicalnetwork/eligibility/v3")
  end

  def test_reports_uses_shared_client
    @healthcare.reports.get_835(transaction_id: "abc")

    assert @client.got?(path: "/change/medicalnetwork/reports/v2/abc/835")
  end
end
