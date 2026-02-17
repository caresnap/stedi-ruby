# frozen_string_literal: true

module Stedi
  module Healthcare
    class Eligibility
      ENDPOINT = "/change/medicalnetwork/eligibility/v3"

      def initialize(client: nil)
        @client = client || Stedi::Client.new(api_url: API_URL)
      end

      def check(params)
        @client.post(ENDPOINT, params)
      end
    end
  end
end
