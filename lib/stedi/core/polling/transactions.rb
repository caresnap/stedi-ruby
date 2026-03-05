# frozen_string_literal: true

require "date"
require_relative "transactions/log"

module Stedi
  module Core
    module Polling
      class Transactions
        include Dependency
        include Log::Dependency

        ENDPOINT = "/polling/transactions"

        dependency :session, Stedi::Core::Session

        def self.configure(receiver, session: nil, attr_name: nil)
          attr_name ||= :poll_transactions
          instance = build(session:)
          receiver.public_send("#{attr_name}=", instance)
        end

        def self.build(session: nil)
          instance = new
          instance.configure(session:)
          instance
        end

        def self.call(start_date_time = nil, page_token: nil, page_size: nil, session: nil)
          instance = build(session:)
          instance.(start_date_time, page_token:, page_size:)
        end

        def configure(session: nil)
          Stedi::Core::Session.configure(self, session:, attr_name: :session)
        end

        def call(start_date_time = nil, page_token: nil, page_size: nil)
          validate_required_polling_params(start_date_time, page_token)

          params = {
            start_date_time: normalize_start_date_time(start_date_time),
            page_token: page_token,
            page_size: page_size
          }.reject { |_, value| value.nil? }

          logger.trace { "Polling transactions. (Params: #{params})" }

          session.(:get, ENDPOINT, params:)
        end

        private

        def validate_required_polling_params(start_date_time, page_token)
          return if start_date_time || page_token

          raise ArgumentError, "Provide either start_date_time or page_token"
        end

        def normalize_start_date_time(start_date_time)
          return nil if start_date_time.nil?
          return start_date_time if start_date_time.is_a?(String)
          return start_date_time.iso8601 if start_date_time.respond_to?(:iso8601)

          start_date_time.to_s
        end

        module Substitute
          class Transactions
            attr_reader :calls
            attr_accessor :response
            attr_accessor :error

            def initialize
              @calls = []
              @response = Response.new({ "items" => [] })
            end

            def call(start_date_time = nil, page_token: nil, page_size: nil)
              @calls << {
                start_date_time: start_date_time,
                page_token: page_token,
                page_size: page_size
              }

              raise error if error

              response
            end
          end

          def self.build
            Transactions.new
          end

          def self.configure(receiver, transactions: nil, attr_name: nil)
            attr_name ||= :poll_transactions
            receiver.public_send("#{attr_name}=", transactions || build)
          end
        end
      end
    end
  end
end
