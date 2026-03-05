# frozen_string_literal: true

module Stedi
  module Healthcare
    API_URL = "https://healthcare.us.stedi.com/2024-04-01"
  end
end

require_relative "healthcare/session"
require_relative "healthcare/eligibility"
require_relative "healthcare/reports"
