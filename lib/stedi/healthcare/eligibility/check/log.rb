# frozen_string_literal: true

module Stedi
  module Healthcare
    module Eligibility
      class Check
        class Log < ::Log
          def tag!(tags)
            tags << :stedi
            tags << :healthcare
            tags << :eligibility
            tags << :check
          end
        end
      end
    end
  end
end
