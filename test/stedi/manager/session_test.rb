# frozen_string_literal: true

require "test_helper"

class Stedi::Manager::SessionTest < Minitest::Test
  Receiver = Struct.new(:session)

  def test_class_configure_assigns_instance
    receiver = Receiver.new

    Stedi::Manager::Session.configure(receiver)

    assert_instance_of Stedi::Manager::Session, receiver.session
  end

  def test_call_delegates_to_http_session
    http_session = Stedi::HTTP::Session::Substitute.build
    http_session.response = Stedi::Response.new({ "ok" => true })

    session = Stedi::Manager::Session.build(http_session: http_session)
    response = session.(
      :post,
      "/eligibility-manager/batch-eligibility",
      body: { items: [] },
      headers: { "X-Forwarded-For" => "203.0.113.10" }
    )

    assert_equal true, response.ok
    assert_equal :post, http_session.calls.last[:method]
    assert_equal "/eligibility-manager/batch-eligibility", http_session.calls.last[:path]
    assert_equal({ "X-Forwarded-For" => "203.0.113.10" }, http_session.calls.last[:headers])
  end

  def test_class_call_delegates_to_built_instance
    http_session = Stedi::HTTP::Session::Substitute.build
    http_session.response = Stedi::Response.new({ "ok" => true })

    response = Stedi::Manager::Session.call(:get, "/x", http_session: http_session)

    assert_equal true, response.ok
  end

  def test_substitute_records_calls
    substitute = Stedi::Manager::Session::Substitute.build
    substitute.response = Stedi::Response.new({ "ok" => true })

    response = substitute.(:get, "/x")

    assert_equal true, response.ok
    assert_equal :get, substitute.calls.last[:method]
  end
end
