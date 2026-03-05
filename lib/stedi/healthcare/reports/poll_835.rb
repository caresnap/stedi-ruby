# frozen_string_literal: true

require_relative "poll_835/log"

module Stedi
  module Healthcare
    module Reports
      class Poll835
        include Dependency
        include Log::Dependency

        dependency :poll_transactions, Stedi::Core::Polling::Transactions
        dependency :get_835, Stedi::Healthcare::Reports::Get835

        def self.configure(receiver, poll_transactions: nil, get_835: nil, attr_name: nil)
          attr_name ||= :poll_835
          instance = build(poll_transactions:, get_835:)
          receiver.public_send("#{attr_name}=", instance)
        end

        def self.build(poll_transactions: nil, get_835: nil)
          instance = new
          instance.configure(poll_transactions:, get_835:)
          instance
        end

        def self.call(start_date_time = nil, page_token: nil, page_size: nil, poll_transactions: nil, get_835: nil)
          instance = build(poll_transactions:, get_835:)
          instance.(start_date_time, page_token:, page_size:)
        end

        def configure(poll_transactions: nil, get_835: nil)
          if poll_transactions
            self.poll_transactions = poll_transactions
          else
            Stedi::Core::Polling::Transactions.configure(self, attr_name: :poll_transactions)
          end

          if get_835
            self.get_835 = get_835
          else
            Stedi::Healthcare::Reports::Get835.configure(self, attr_name: :get_835)
          end
        end

        def call(start_date_time = nil, page_token: nil, page_size: nil)
          logger.trace { "Polling 835 reports." }

          poll_response = poll_transactions.(start_date_time, page_token:, page_size:)
          transactions = Array(poll_response.items).select { |transaction| inbound_835?(transaction) }
          reports = transactions.map { |transaction| get_835.(transaction.transaction_id) }

          Response.new(
            "transactions" => transactions.map(&:to_h),
            "reports" => reports.map(&:to_h),
            "nextPageToken" => poll_response.next_page_token
          )
        end

        private

        def inbound_835?(transaction)
          transaction.direction == "INBOUND" && transaction_set_identifier(transaction) == "835"
        end

        def transaction_set_identifier(transaction)
          x12 = transaction.x12
          return nil unless x12

          metadata = x12.metadata
          return nil unless metadata

          details = metadata.transaction
          return nil unless details

          details.transaction_set_identifier
        end

        module Substitute
          class Poll835
            attr_reader :calls
            attr_accessor :response
            attr_accessor :error

            def initialize
              @calls = []
              @response = Response.new({
                "transactions" => [],
                "reports" => []
              })
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
            Poll835.new
          end

          def self.configure(receiver, poll_835: nil, attr_name: nil)
            attr_name ||= :poll_835
            receiver.public_send("#{attr_name}=", poll_835 || build)
          end
        end
      end
    end
  end
end
