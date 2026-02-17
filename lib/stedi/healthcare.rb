# frozen_string_literal: true

require_relative "healthcare/eligibility"
require_relative "healthcare/reports"

module Stedi
  module Healthcare
    API_URL = "https://healthcare.us.stedi.com/2024-04-01"

    class Client
      def initialize(client: nil, core_client: nil)
        @client = client || Stedi::Client.new(api_url: API_URL)
        @core_client = core_client || Stedi.core
      end

      def eligibility
        @eligibility ||= Eligibility.new(client: @client)
      end

      def reports
        @reports ||= Reports.new(client: @client, polling: @core_client.polling)
      end
    end
  end
end
