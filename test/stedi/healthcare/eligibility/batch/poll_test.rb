# frozen_string_literal: true

require "test_helper"
require "date"

class Stedi::Healthcare::Eligibility::Batch::PollTest < Minitest::Test
  Receiver = Struct.new(:poll_eligibility_batch)

  def setup
    super
    @session = Stedi::Manager::Session::Substitute.build
    @session.response = Stedi::Response.new({
      "items" => [],
      "nextPageToken" => "next-page"
    })
    @poll = Stedi::Healthcare::Eligibility::Batch::Poll.build(session: @session)
  end

  def test_call_polls_batch_results_endpoint
    @poll.(nil, batch_id: "01932c61-2d4f-7d22-85fa-c7db2e13e771")

    assert_equal :get, @session.calls.last[:method]
    assert_equal "/eligibility-manager/polling/batch-eligibility", @session.calls.last[:path]
  end

  def test_call_sends_query_params
    @poll.("2026-03-01T00:00:00Z", batch_id: "01932c61-2d4f-7d22-85fa-c7db2e13e771", page_size: 50)

    assert_equal(
      {
        start_date_time: "2026-03-01T00:00:00Z",
        batch_id: "01932c61-2d4f-7d22-85fa-c7db2e13e771",
        page_size: 50
      },
      @session.calls.last[:params]
    )
  end

  def test_call_adds_gzip_header_when_page_size_exceeds_twenty
    @poll.(nil, batch_id: "01932c61-2d4f-7d22-85fa-c7db2e13e771", page_size: 25)

    assert_equal({ "Accept-Encoding" => "gzip" }, @session.calls.last[:headers])
  end

  def test_call_preserves_explicit_accept_encoding_header
    @poll.(
      nil,
      batch_id: "01932c61-2d4f-7d22-85fa-c7db2e13e771",
      page_size: 25,
      headers: { "Accept-Encoding" => "br" }
    )

    assert_equal({ "Accept-Encoding" => "br" }, @session.calls.last[:headers])
  end

  def test_call_serializes_time_to_iso8601
    timestamp = Time.utc(2026, 3, 1, 12, 30, 15)

    @poll.(timestamp, batch_id: "01932c61-2d4f-7d22-85fa-c7db2e13e771")

    assert_equal timestamp.iso8601, @session.calls.last[:params][:start_date_time]
  end

  def test_call_serializes_datetime_to_iso8601
    timestamp = DateTime.new(2026, 3, 1, 12, 30, 15, "+00:00")

    @poll.(timestamp, batch_id: "01932c61-2d4f-7d22-85fa-c7db2e13e771")

    assert_equal timestamp.iso8601, @session.calls.last[:params][:start_date_time]
  end

  def test_call_accepts_page_token_without_other_filters
    @poll.(nil, page_token: "next-page")

    assert_equal({ page_token: "next-page" }, @session.calls.last[:params])
  end

  def test_call_raises_when_batch_id_start_date_time_and_page_token_missing
    error = assert_raises(ArgumentError) do
      @poll.()
    end

    assert_equal "Provide batch_id, start_date_time, or page_token", error.message
  end

  def test_class_configure_assigns_instance
    receiver = Receiver.new

    Stedi::Healthcare::Eligibility::Batch::Poll.configure(receiver)

    assert_instance_of Stedi::Healthcare::Eligibility::Batch::Poll, receiver.poll_eligibility_batch
  end

  def test_class_call_runs_with_injected_session
    response = Stedi::Healthcare::Eligibility::Batch::Poll.call(
      nil,
      batch_id: "01932c61-2d4f-7d22-85fa-c7db2e13e771",
      session: @session
    )

    assert_equal "next-page", response.next_page_token
  end

  def test_substitute_records_calls
    substitute = Stedi::Healthcare::Eligibility::Batch::Poll::Substitute.build

    substitute.(nil, batch_id: "01932c61-2d4f-7d22-85fa-c7db2e13e771", page_size: 10)

    assert_equal "01932c61-2d4f-7d22-85fa-c7db2e13e771", substitute.calls.last[:batch_id]
    assert_equal 10, substitute.calls.last[:page_size]
  end
end
