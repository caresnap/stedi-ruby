# frozen_string_literal: true

require_relative "core/polling"

module Stedi
  module Core
    API_URL = "https://core.us.stedi.com/2023-08-01"

    class Client
      def initialize(client: nil)
        @client = client || Stedi::Client.new(api_url: API_URL)
      end

      def polling
        @polling ||= Polling.new(client: @client)
      end
    end
  end
end
