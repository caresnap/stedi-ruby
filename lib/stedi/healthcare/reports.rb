# frozen_string_literal: true

module Stedi
  module Healthcare
    class Reports
      ENDPOINT = "/change/medicalnetwork/reports/v2"

      def initialize(client: nil, polling: nil)
        @client = client || Stedi::Client.new(api_url: API_URL)
        @polling = polling || Stedi.core.polling
      end

      def get_835(transaction_id:)
        @client.get("#{ENDPOINT}/#{transaction_id}/835")
      end

      def poll_835(start_date_time: nil, page_token: nil, page_size: nil)
        poll_response = @polling.transactions(
          start_date_time: start_date_time,
          page_token: page_token,
          page_size: page_size
        )

        transactions = Array(poll_response.items).select { |transaction| inbound_835?(transaction) }
        reports = transactions.map { |transaction| get_835(transaction_id: transaction.transaction_id) }

        Stedi::Response.new(
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

        data = metadata.transaction
        return nil unless data

        data.transaction_set_identifier
      end
    end
  end
end
