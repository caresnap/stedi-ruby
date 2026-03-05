# frozen_string_literal: true

module Stedi
  module Healthcare
    module Reports
      class Poll835
        class Log < ::Log
          def tag!(tags)
            tags << :stedi
            tags << :healthcare
            tags << :reports
            tags << :poll_835
          end
        end
      end
    end
  end
end
