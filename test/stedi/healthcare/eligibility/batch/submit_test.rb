# frozen_string_literal: true

require "test_helper"

class Stedi::Healthcare::Eligibility::Batch::SubmitTest < Minitest::Test
  Receiver = Struct.new(:submit_eligibility_batch)

  def setup
    super
    @session = Stedi::Manager::Session::Substitute.build
    @session.response = Stedi::Response.new({
      "batchId" => "01928d19-df25-76c0-8d51-f5351260fa05",
      "submittedAt" => "2023-11-07T05:31:56Z"
    })
    @submit = Stedi::Healthcare::Eligibility::Batch::Submit.build(session: @session)
  end

  def items
    [
      {
        trading_partner_service_id: "AHS",
        submitter_transaction_identifier: "ABC123456789",
        provider: {
          npi: "1234567891",
          organization_name: "ACME Health Services"
        },
        subscriber: {
          member_id: "1234567890",
          first_name: "Jane",
          last_name: "Doe",
          date_of_birth: "19000101"
        }
      }
    ]
  end

  def test_call_posts_to_batch_eligibility_endpoint
    response = @submit.(items, name: "march-2026-eligibility-batch", max_retry_hours: 12)

    assert_equal "01928d19-df25-76c0-8d51-f5351260fa05", response.batch_id
    assert_equal :post, @session.calls.last[:method]
    assert_equal "/eligibility-manager/batch-eligibility", @session.calls.last[:path]
    assert_equal(
      {
        items: items,
        name: "march-2026-eligibility-batch",
        max_retry_hours: 12
      },
      @session.calls.last[:body]
    )
  end

  def test_call_adds_x_forwarded_for_header
    @submit.(items, x_forwarded_for: ["203.0.113.10", "198.51.100.7"])

    assert_equal(
      { "X-Forwarded-For" => "203.0.113.10, 198.51.100.7" },
      @session.calls.last[:headers]
    )
  end

  def test_class_configure_assigns_instance
    receiver = Receiver.new

    Stedi::Healthcare::Eligibility::Batch::Submit.configure(receiver)

    assert_instance_of Stedi::Healthcare::Eligibility::Batch::Submit, receiver.submit_eligibility_batch
  end

  def test_class_call_runs_with_injected_session
    response = Stedi::Healthcare::Eligibility::Batch::Submit.call(items, session: @session)

    assert_equal "01928d19-df25-76c0-8d51-f5351260fa05", response.batch_id
  end

  def test_substitute_records_calls
    substitute = Stedi::Healthcare::Eligibility::Batch::Submit::Substitute.build

    substitute.(items, name: "test-batch")

    assert_equal items, substitute.calls.last[:items]
    assert_equal "test-batch", substitute.calls.last[:name]
  end
end
