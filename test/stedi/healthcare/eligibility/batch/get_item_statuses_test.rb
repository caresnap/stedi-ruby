# frozen_string_literal: true

require "test_helper"

class Stedi::Healthcare::Eligibility::Batch::GetItemStatusesTest < Minitest::Test
  Receiver = Struct.new(:get_eligibility_batch_item_statuses)

  def setup
    super
    @session = Stedi::Manager::Session::Substitute.build
    @session.response = Stedi::Response.new({
      "items" => [],
      "nextPageToken" => "next-page"
    })
    @get_item_statuses = Stedi::Healthcare::Eligibility::Batch::GetItemStatuses.build(session: @session)
  end

  def test_call_fetches_batch_items_with_query_params
    response = @get_item_statuses.(
      "01932c61-2d4f-7d22-85fa-c7db2e13e771",
      page_size: 250,
      page_token: "next-page",
      state: ["COMPLETED", "COMPLETED_WITH_ERRORS"]
    )

    assert_equal "next-page", response.next_page_token
    assert_equal :get, @session.calls.last[:method]
    assert_equal "/eligibility-manager/batch/01932c61-2d4f-7d22-85fa-c7db2e13e771/items", @session.calls.last[:path]
    assert_equal(
      {
        page_size: 250,
        page_token: "next-page",
        state: ["COMPLETED", "COMPLETED_WITH_ERRORS"]
      },
      @session.calls.last[:params]
    )
  end

  def test_class_configure_assigns_instance
    receiver = Receiver.new

    Stedi::Healthcare::Eligibility::Batch::GetItemStatuses.configure(receiver)

    assert_instance_of Stedi::Healthcare::Eligibility::Batch::GetItemStatuses, receiver.get_eligibility_batch_item_statuses
  end

  def test_class_call_runs_with_injected_session
    response = Stedi::Healthcare::Eligibility::Batch::GetItemStatuses.call(
      "01932c61-2d4f-7d22-85fa-c7db2e13e771",
      session: @session
    )

    assert_equal "next-page", response.next_page_token
  end

  def test_substitute_records_calls
    substitute = Stedi::Healthcare::Eligibility::Batch::GetItemStatuses::Substitute.build

    substitute.("01932c61-2d4f-7d22-85fa-c7db2e13e771", page_size: 10)

    assert_equal "01932c61-2d4f-7d22-85fa-c7db2e13e771", substitute.calls.last[:batch_id]
    assert_equal 10, substitute.calls.last[:page_size]
  end
end
