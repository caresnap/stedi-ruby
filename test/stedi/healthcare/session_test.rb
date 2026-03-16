# frozen_string_literal: true

require "test_helper"

class Stedi::Healthcare::SessionTest < Minitest::Test
  Receiver = Struct.new(:session)

  def test_class_configure_assigns_instance
    receiver = Receiver.new

    Stedi::Healthcare::Session.configure(receiver)

    assert_instance_of Stedi::Healthcare::Session, receiver.session
  end

  def test_call_delegates_to_http_session
    http_session = Stedi::HTTP::Session::Substitute.build
    http_session.response = Stedi::Response.new({ "ok" => true })

    session = Stedi::Healthcare::Session.build(http_session: http_session)
    response = session.(
      :post,
      "/change/medicalnetwork/eligibility/v3",
      body: { a: 1 },
      headers: { "X-Forwarded-For" => "203.0.113.10" }
    )

    assert_equal true, response.ok
    assert_equal :post, http_session.calls.last[:method]
    assert_equal({ "X-Forwarded-For" => "203.0.113.10" }, http_session.calls.last[:headers])
  end

  def test_call_delegates_timeout_to_http_session
    http_session = Stedi::HTTP::Session::Substitute.build
    http_session.response = Stedi::Response.new({ "ok" => true })

    session = Stedi::Healthcare::Session.build(http_session: http_session)
    response = session.(:get, "/x", timeout: 120)

    assert_equal true, response.ok
    assert_equal 120, http_session.calls.last[:timeout]
  end

  def test_class_call_delegates_to_built_instance
    http_session = Stedi::HTTP::Session::Substitute.build
    http_session.response = Stedi::Response.new({ "ok" => true })

    response = Stedi::Healthcare::Session.call(:get, "/x", http_session: http_session)

    assert_equal true, response.ok
  end

  def test_substitute_records_calls
    substitute = Stedi::Healthcare::Session::Substitute.build
    substitute.response = Stedi::Response.new({ "ok" => true })

    response = substitute.(:get, "/x")

    assert_equal true, response.ok
    assert_equal :get, substitute.calls.last[:method]
  end
end
