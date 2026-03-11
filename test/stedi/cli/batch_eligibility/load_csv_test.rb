# frozen_string_literal: true

require "test_helper"
require "stedi/cli/batch_eligibility"
require "tmpdir"

class Stedi::CLI::BatchEligibility::LoadCSVTest < Minitest::Test
  def with_csv(contents)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "batch.csv")
      File.write(path, contents)
      yield path
    end
  end

  def template_headers
    File.read("/Users/james/src/caresnap/stedi-ruby/data/batch-eligibility-template.csv").strip
  end

  def loader
    Stedi::CLI::BatchEligibility::LoadCSV.build
  end

  def test_accepts_template_headers_and_maps_row
    csv = <<~CSV
      #{template_headers}
      AHS,ABC123456789,ACME Health Services,,,1234567891,,20260311,,,30,1234567890,Jane,Doe,19000101,GRP123,,,,
    CSV

    with_csv(csv) do |path|
      items = loader.(path)

      assert_equal 1, items.length
      assert_equal(
        {
          trading_partner_service_id: "AHS",
          submitter_transaction_identifier: "ABC123456789",
          provider: {
            organization_name: "ACME Health Services",
            npi: "1234567891"
          },
          encounter: {
            date_of_service: "20260311",
            service_type_codes: ["30"]
          },
          subscriber: {
            member_id: "1234567890",
            first_name: "Jane",
            last_name: "Doe",
            date_of_birth: "19000101",
            group_number: "GRP123"
          }
        },
        items.first
      )
    end
  end

  def test_rejects_unknown_headers
    csv = <<~CSV
      #{template_headers},extraHeader
      AHS,ABC123456789,ACME Health Services,,,1234567891,,20260311,,,30,1234567890,Jane,Doe,19000101,GRP123,,,,,x
    CSV

    with_csv(csv) do |path|
      error = assert_raises(ArgumentError) do
        loader.(path)
      end

      assert_equal "Unsupported CSV headers: extraHeader", error.message
    end
  end

  def test_rejects_missing_headers
    csv = <<~CSV
      tradingPartnerServiceId,submitterTransactionIdentifier
      AHS,ABC123456789
    CSV

    with_csv(csv) do |path|
      error = assert_raises(ArgumentError) do
        loader.(path)
      end

      assert_includes error.message, "Missing CSV headers:"
      assert_includes error.message, "providerOrganizationName"
    end
  end

  def test_splits_service_type_codes
    csv = <<~CSV
      #{template_headers}
      AHS,ABC123456789,ACME Health Services,,,1234567891,,,,,"30, 33, MH",1234567890,Jane,Doe,19000101,,,,,
    CSV

    with_csv(csv) do |path|
      items = loader.(path)

      assert_equal ["30", "33", "MH"], items.first[:encounter][:service_type_codes]
    end
  end

  def test_omits_blank_nested_fields
    csv = <<~CSV
      #{template_headers}
      AHS,ABC123456789,,,,,,,,,,1234567890,,,19000101,,,,,
    CSV

    with_csv(csv) do |path|
      items = loader.(path)

      assert_equal(
        {
          trading_partner_service_id: "AHS",
          submitter_transaction_identifier: "ABC123456789",
          subscriber: {
            member_id: "1234567890",
            date_of_birth: "19000101"
          }
        },
        items.first
      )
    end
  end

  def test_creates_dependents_only_when_present
    csv = <<~CSV
      #{template_headers}
      AHS,ABC123456789,ACME Health Services,,,1234567891,,20260311,,,30,1234567890,Jane,Doe,19000101,,D001,Junior,Doe,20150101
    CSV

    with_csv(csv) do |path|
      items = loader.(path)

      assert_equal(
        [
          {
            member_id: "D001",
            first_name: "Junior",
            last_name: "Doe",
            date_of_birth: "20150101"
          }
        ],
        items.first[:dependents]
      )
    end
  end
end
