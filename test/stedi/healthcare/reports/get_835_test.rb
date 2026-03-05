# frozen_string_literal: true

require "test_helper"

class Stedi::Healthcare::Reports::Get835Test < Minitest::Test
  Receiver = Struct.new(:get_835)

  def setup
    super
    @session = Stedi::Healthcare::Session::Substitute.build
    @session.response = Stedi::Response.new({ "meta" => { "transactionId" => "txn-123" }, "transactions" => [] })
    @get_835 = Stedi::Healthcare::Reports::Get835.build(session: @session)
  end

  def test_call_gets_835_endpoint
    response = @get_835.("txn-123")

    assert_equal "txn-123", response.meta.transaction_id
    assert_equal :get, @session.calls.last[:method]
    assert_equal "/change/medicalnetwork/reports/v2/txn-123/835", @session.calls.last[:path]
  end

  def test_class_configure_assigns_instance
    receiver = Receiver.new

    Stedi::Healthcare::Reports::Get835.configure(receiver)

    assert_instance_of Stedi::Healthcare::Reports::Get835, receiver.get_835
  end

  def test_class_call_runs_with_injected_session
    response = Stedi::Healthcare::Reports::Get835.call("txn-123", session: @session)

    assert_equal "txn-123", response.meta.transaction_id
  end

  def test_substitute_records_calls
    substitute = Stedi::Healthcare::Reports::Get835::Substitute.build

    substitute.("txn-xyz")

    assert_equal "txn-xyz", substitute.calls.last[:transaction_id]
  end
end
