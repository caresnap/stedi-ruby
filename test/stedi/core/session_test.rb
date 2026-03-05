# frozen_string_literal: true

require "test_helper"

class Stedi::Core::SessionTest < Minitest::Test
  Receiver = Struct.new(:session)

  def test_class_configure_assigns_instance
    receiver = Receiver.new

    Stedi::Core::Session.configure(receiver)

    assert_instance_of Stedi::Core::Session, receiver.session
  end

  def test_call_delegates_to_http_session
    http_session = Stedi::HTTP::Session::Substitute.build
    http_session.response = Stedi::Response.new({ "ok" => true })

    session = Stedi::Core::Session.build(http_session: http_session)
    response = session.(:get, "/polling/transactions", params: { start_date_time: "2026-02-11T00:00:00Z" })

    assert_equal true, response.ok
    assert_equal :get, http_session.calls.last[:method]
    assert_equal "/polling/transactions", http_session.calls.last[:path]
  end

  def test_class_call_delegates_to_built_instance
    http_session = Stedi::HTTP::Session::Substitute.build
    http_session.response = Stedi::Response.new({ "ok" => true })

    response = Stedi::Core::Session.call(:get, "/polling/transactions", http_session: http_session)

    assert_equal true, response.ok
  end

  def test_substitute_records_calls
    substitute = Stedi::Core::Session::Substitute.build
    substitute.response = Stedi::Response.new({ "ok" => true })

    response = substitute.(:get, "/x")

    assert_equal true, response.ok
    assert_equal :get, substitute.calls.last[:method]
  end
end
