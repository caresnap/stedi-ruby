# frozen_string_literal: true

require_relative "healthcare/eligibility"

module Stedi
  module Healthcare
    class Client
      def eligibility
        @eligibility ||= Eligibility.new
      end
    end
  end
end
