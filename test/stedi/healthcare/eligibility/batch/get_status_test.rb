# frozen_string_literal: true

require "test_helper"

class Stedi::Healthcare::Eligibility::Batch::GetStatusTest < Minitest::Test
  Receiver = Struct.new(:get_eligibility_batch_status)

  def setup
    super
    @session = Stedi::Manager::Session::Substitute.build
    @session.response = Stedi::Response.new({
      "id" => "01976a49-05f4-7421-bc33-aed86f1fccc6",
      "status" => "COMPLETED",
      "totalCount" => 9000
    })
    @get_status = Stedi::Healthcare::Eligibility::Batch::GetStatus.build(session: @session)
  end

  def test_call_fetches_batch_status
    response = @get_status.("01976a49-05f4-7421-bc33-aed86f1fccc6")

    assert_equal "COMPLETED", response.status
    assert_equal :get, @session.calls.last[:method]
    assert_equal "/eligibility-manager/batch/01976a49-05f4-7421-bc33-aed86f1fccc6", @session.calls.last[:path]
  end

  def test_class_configure_assigns_instance
    receiver = Receiver.new

    Stedi::Healthcare::Eligibility::Batch::GetStatus.configure(receiver)

    assert_instance_of Stedi::Healthcare::Eligibility::Batch::GetStatus, receiver.get_eligibility_batch_status
  end

  def test_class_call_runs_with_injected_session
    response = Stedi::Healthcare::Eligibility::Batch::GetStatus.call(
      "01976a49-05f4-7421-bc33-aed86f1fccc6",
      session: @session
    )

    assert_equal 9000, response.total_count
  end

  def test_substitute_records_calls
    substitute = Stedi::Healthcare::Eligibility::Batch::GetStatus::Substitute.build

    substitute.("01976a49-05f4-7421-bc33-aed86f1fccc6")

    assert_equal "01976a49-05f4-7421-bc33-aed86f1fccc6", substitute.calls.last[:batch_id]
  end
end
