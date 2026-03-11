# frozen_string_literal: true

require "csv"

module Stedi
  module CLI
    module BatchEligibility
      class LoadCSV
        TEMPLATE_PATH = File.expand_path("../../../../data/batch-eligibility-template.csv", __dir__)

        attr_reader :template_path

        def self.configure(receiver, load_csv: nil, template_path: nil, attr_name: nil)
          attr_name ||= :load_csv
          instance = load_csv || build(template_path:)
          receiver.public_send("#{attr_name}=", instance)
        end

        def self.build(template_path: nil)
          new(template_path:)
        end

        def self.call(csv_path, template_path: nil)
          instance = build(template_path:)
          instance.(csv_path)
        end

        def initialize(template_path: nil)
          @template_path = template_path || TEMPLATE_PATH
        end

        def call(csv_path)
          validate_headers(csv_path)

          CSV.foreach(csv_path, headers: true).each_with_object([]) do |row, items|
            row_hash = normalize_row(row.to_h)
            next if blank_row?(row_hash)

            items << build_item(row_hash)
          end
        end

        private

        def validate_headers(csv_path)
          actual = csv_headers(csv_path)
          expected = template_headers

          unknown = actual - expected
          missing = expected - actual

          unless unknown.empty?
            raise ArgumentError, "Unsupported CSV headers: #{unknown.join(', ')}"
          end

          unless missing.empty?
            raise ArgumentError, "Missing CSV headers: #{missing.join(', ')}"
          end
        end

        def csv_headers(csv_path)
          headers = CSV.open(csv_path, &:first)
          raise ArgumentError, "CSV file is empty: #{csv_path}" if headers.nil?

          normalize_headers(headers)
        end

        def template_headers
          @template_headers ||= csv_headers(template_path)
        end

        def normalize_headers(headers)
          headers.map { |header| normalize_string(header) }
        end

        def normalize_row(row_hash)
          row_hash.each_with_object({}) do |(key, value), normalized|
            normalized[normalize_string(key)] = normalize_string(value)
          end
        end

        def normalize_string(value)
          string = value.to_s
          string = string.sub(/\A\uFEFF/, "")
          string.strip
        end

        def blank_row?(row_hash)
          row_hash.values.all?(&:empty?)
        end

        def build_item(row)
          item = {
            trading_partner_service_id: row["tradingPartnerServiceId"],
            submitter_transaction_identifier: row["submitterTransactionIdentifier"],
            provider: provider(row),
            encounter: encounter(row),
            subscriber: subscriber(row),
            dependents: dependents(row)
          }

          compact_value(item)
        end

        def provider(row)
          {
            organization_name: row["providerOrganizationName"],
            first_name: row["providerFirstName"],
            last_name: row["providerLastName"],
            npi: row["providerNpi"],
            tax_id: row["providerTaxId"]
          }
        end

        def encounter(row)
          {
            date_of_service: row["encounterDateOfService"],
            beginning_date_of_service: row["encounterBeginningDateOfService"],
            end_date_of_service: row["encounterEndDateOfService"],
            service_type_codes: service_type_codes(row["serviceTypeCodes"])
          }
        end

        def subscriber(row)
          {
            member_id: row["subscriberMemberId"],
            first_name: row["subscriberFirstName"],
            last_name: row["subscriberLastName"],
            date_of_birth: row["subscriberDateOfBirth"],
            group_number: row["subscriberGroupNumber"]
          }
        end

        def dependents(row)
          dependent = compact_value(
            member_id: row["dependentMemberId"],
            first_name: row["dependentFirstName"],
            last_name: row["dependentLastName"],
            date_of_birth: row["dependentDateOfBirth"]
          )

          dependent.empty? ? [] : [dependent]
        end

        def service_type_codes(value)
          return [] if value.empty?

          value.split(",").map(&:strip).reject(&:empty?)
        end

        def compact_value(value)
          case value
          when Hash
            value.each_with_object({}) do |(key, nested_value), compacted|
              next_value = compact_value(nested_value)
              compacted[key] = next_value unless empty_value?(next_value)
            end
          when Array
            value.filter_map do |nested_value|
              next_value = compact_value(nested_value)
              next_value unless empty_value?(next_value)
            end
          else
            value
          end
        end

        def empty_value?(value)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end

        module Substitute
          class LoadCSV
            attr_reader :calls
            attr_accessor :items
            attr_accessor :error

            def initialize
              @calls = []
              @items = []
            end

            def call(csv_path)
              @calls << { csv_path: csv_path }
              raise error if error

              items
            end
          end

          def self.build
            LoadCSV.new
          end

          def self.configure(receiver, load_csv: nil, attr_name: nil)
            attr_name ||= :load_csv
            receiver.public_send("#{attr_name}=", load_csv || build)
          end
        end
      end
    end
  end
end
