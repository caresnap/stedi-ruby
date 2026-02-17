# frozen_string_literal: true

require "test_helper"

class Stedi::Core::ClientTest < Minitest::Test
  def test_polling_uses_supplied_client
    client = Stedi::Client::Substitute.build
    client.response_body = { "items" => [] }
    core = Stedi::Core::Client.new(client: client)

    core.polling.transactions(start_date_time: "2026-02-11T00:00:00Z")

    assert client.got?(path: "/polling/transactions")
  end
end
