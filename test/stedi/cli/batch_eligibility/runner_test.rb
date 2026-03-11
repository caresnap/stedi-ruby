# frozen_string_literal: true

require "test_helper"
require "stedi/cli/batch_eligibility"
require "stringio"
require "tmpdir"

class Stedi::CLI::BatchEligibility::RunnerTest < Minitest::Test
  def build_runner(load_csv: nil, submit_batch: nil, get_batch_status: nil, get_batch_items: nil, poll_batch: nil)
    Stedi::CLI::BatchEligibility::Runner.build(
      load_csv: load_csv,
      submit_batch: submit_batch,
      get_batch_status: get_batch_status,
      get_batch_items: get_batch_items,
      poll_batch: poll_batch
    )
  end

  def with_csv
    Dir.mktmpdir do |dir|
      path = File.join(dir, "march-2026-eligibility-batch.csv")
      File.write(path, "tradingPartnerServiceId\nAHS\n")
      yield path
    end
  end

  def env
    { "STEDI_API_KEY" => "test_api_key" }
  end

  def test_default_mode_calls_submit_with_items_and_basename_batch_name
    load_csv = Stedi::CLI::BatchEligibility::LoadCSV::Substitute.build
    load_csv.items = [{ trading_partner_service_id: "AHS" }]
    submit = Stedi::Healthcare::Eligibility::Batch::Submit::Substitute.build
    submit.response = Stedi::Response.new({ "batchId" => "batch-123" })

    runner = build_runner(load_csv:, submit_batch: submit)
    stdout = StringIO.new
    stderr = StringIO.new

    with_csv do |path|
      exit_code = runner.([path], stdout:, stderr:, env:)

      assert_equal 0, exit_code
      assert_equal [{ trading_partner_service_id: "AHS" }], submit.calls.last[:items]
      assert_equal "march-2026-eligibility-batch", submit.calls.last[:name]
      assert_equal "batch-123\n", File.read(path.sub(/\.csv\z/, ".batch_id"))
      assert_equal({ "batch_id" => "batch-123" }, JSON.parse(stdout.string))
      assert_equal "", stderr.string
    end
  end

  def test_get_status_reads_sidecar_and_calls_get_status
    get_status = Stedi::Healthcare::Eligibility::Batch::GetStatus::Substitute.build
    get_status.response = Stedi::Response.new({ "status" => "COMPLETED" })
    runner = build_runner(get_batch_status: get_status)
    stdout = StringIO.new

    with_csv do |path|
      File.write(path.sub(/\.csv\z/, ".batch_id"), "batch-123\n")

      exit_code = runner.([path, "--status"], stdout:, stderr: StringIO.new, env:)

      assert_equal 0, exit_code
      assert_equal "batch-123", get_status.calls.last[:batch_id]
      assert_equal({ "status" => "COMPLETED" }, JSON.parse(stdout.string))
    end
  end

  def test_get_items_reads_sidecar_and_calls_get_items
    get_items = Stedi::Healthcare::Eligibility::Batch::GetItemStatuses::Substitute.build
    get_items.response = Stedi::Response.new({ "items" => [] })
    runner = build_runner(get_batch_items: get_items)
    stdout = StringIO.new

    with_csv do |path|
      File.write(path.sub(/\.csv\z/, ".batch_id"), "batch-123\n")

      exit_code = runner.([path, "--item-statuses"], stdout:, stderr: StringIO.new, env:)

      assert_equal 0, exit_code
      assert_equal "batch-123", get_items.calls.last[:batch_id]
      assert_equal({ "items" => [] }, JSON.parse(stdout.string))
    end
  end

  def test_poll_reads_sidecar_and_calls_poll
    poll = Stedi::Healthcare::Eligibility::Batch::Poll::Substitute.build
    poll.response = Stedi::Response.new({ "items" => [] })
    runner = build_runner(poll_batch: poll)
    stdout = StringIO.new

    with_csv do |path|
      File.write(path.sub(/\.csv\z/, ".batch_id"), "batch-123\n")

      exit_code = runner.([path, "--poll"], stdout:, stderr: StringIO.new, env:)

      assert_equal 0, exit_code
      assert_equal "batch-123", poll.calls.last[:batch_id]
      assert_equal({ "items" => [] }, JSON.parse(stdout.string))
    end
  end

  def test_multiple_mode_flags_fail
    runner = build_runner
    stderr = StringIO.new

    with_csv do |path|
      exit_code = runner.([path, "--status", "--poll"], stdout: StringIO.new, stderr:, env:)

      assert_equal 1, exit_code
      assert_equal "Choose only one of --status, --item-statuses, or --poll\n", stderr.string
    end
  end

  def test_missing_csv_arg_fails
    runner = build_runner
    stderr = StringIO.new

    exit_code = runner.([], stdout: StringIO.new, stderr:, env:)

    assert_equal 1, exit_code
    assert_equal "Provide exactly one CSV file path\n", stderr.string
  end

  def test_missing_api_key_fails
    load_csv = Stedi::CLI::BatchEligibility::LoadCSV::Substitute.build
    runner = build_runner(load_csv:)
    stderr = StringIO.new

    with_csv do |path|
      exit_code = runner.([path], stdout: StringIO.new, stderr:, env: {})

      assert_equal 1, exit_code
      assert_equal "Set STEDI_API_KEY before running this command\n", stderr.string
    end
  end

  def test_missing_sidecar_fails_in_read_only_modes
    runner = build_runner
    stderr = StringIO.new

    with_csv do |path|
      exit_code = runner.([path, "--status"], stdout: StringIO.new, stderr:, env:)

      assert_equal 1, exit_code
      assert_includes stderr.string, "Batch ID sidecar not found:"
      assert_includes stderr.string, ".batch_id"
    end
  end

  def test_missing_csv_file_fails
    runner = build_runner
    stderr = StringIO.new

    exit_code = runner.(["/tmp/does-not-exist.csv"], stdout: StringIO.new, stderr:, env:)

    assert_equal 1, exit_code
    assert_includes stderr.string, "CSV file not found:"
  end
end
