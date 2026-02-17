# frozen_string_literal: true

require "date"

module Stedi
  module Core
    class Polling
      ENDPOINT = "/polling/transactions"

      def initialize(client: nil)
        @client = client || Stedi::Client.new(api_url: API_URL)
      end

      def transactions(start_date_time: nil, page_token: nil, page_size: nil)
        validate_required_polling_params(start_date_time:, page_token:)

        params = {
          start_date_time: normalize_start_date_time(start_date_time),
          page_token: page_token,
          page_size: page_size
        }.reject { |_, value| value.nil? }

        @client.get(ENDPOINT, params)
      end

      private

      def validate_required_polling_params(start_date_time:, page_token:)
        return if start_date_time || page_token

        raise ArgumentError, "Provide either start_date_time or page_token"
      end

      def normalize_start_date_time(start_date_time)
        return nil if start_date_time.nil?
        return start_date_time if start_date_time.is_a?(String)
        return start_date_time.iso8601 if start_date_time.respond_to?(:iso8601)

        start_date_time.to_s
      end
    end
  end
end
