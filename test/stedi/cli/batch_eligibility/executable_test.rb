# frozen_string_literal: true

require "test_helper"
require "stedi/cli/batch_eligibility"
require "stringio"

class Stedi::CLI::BatchEligibility::ExecutableTest < Minitest::Test
  def test_executable_delegates_to_runner
    runner = Stedi::CLI::BatchEligibility::Runner::Substitute.build
    stdout = StringIO.new
    stderr = StringIO.new
    env = { "STEDI_API_KEY" => "test_api_key" }

    exit_code = Stedi::CLI::BatchEligibility::Executable.call(
      ["file.csv", "--poll"],
      stdout:,
      stderr:,
      env:,
      runner:
    )

    assert_equal 0, exit_code
    assert_equal ["file.csv", "--poll"], runner.calls.last[:argv]
    assert_same stdout, runner.calls.last[:stdout]
    assert_same stderr, runner.calls.last[:stderr]
    assert_same env, runner.calls.last[:env]
    assert_equal "trace", env["LOG_LEVEL"]
    assert_equal "stderr", env["CONSOLE_DEVICE"]
    assert_equal "_all", env["LOG_TAGS"]
  end
end
