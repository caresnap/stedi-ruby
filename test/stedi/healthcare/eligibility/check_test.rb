# frozen_string_literal: true

require "test_helper"

class Stedi::Healthcare::Eligibility::CheckTest < Minitest::Test
  Receiver = Struct.new(:check_eligibility)

  def setup
    super
    @session = Stedi::Healthcare::Session::Substitute.build
    @session.response = Stedi::Response.new({ "controlNumber" => "123" })
    @check = Stedi::Healthcare::Eligibility::Check.build(session: @session)
  end

  def params
    {
      trading_partner_service_id: "BCBSIL",
      subscriber: {
        member_id: "ABC123"
      }
    }
  end

  def test_call_posts_to_eligibility_endpoint
    response = @check.(params)

    assert_equal "123", response.control_number
    assert_equal :post, @session.calls.last[:method]
    assert_equal "/change/medicalnetwork/eligibility/v3", @session.calls.last[:path]
    assert_equal params, @session.calls.last[:body]
  end

  def test_class_configure_assigns_instance
    receiver = Receiver.new

    Stedi::Healthcare::Eligibility::Check.configure(receiver)

    assert_instance_of Stedi::Healthcare::Eligibility::Check, receiver.check_eligibility
  end

  def test_class_call_runs_with_injected_session
    response = Stedi::Healthcare::Eligibility::Check.call(params, session: @session)

    assert_equal "123", response.control_number
  end

  def test_substitute_records_calls
    substitute = Stedi::Healthcare::Eligibility::Check::Substitute.build

    substitute.(params)

    assert_equal params, substitute.calls.last[:params]
  end
end
