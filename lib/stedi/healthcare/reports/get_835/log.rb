# frozen_string_literal: true

module Stedi
  module Healthcare
    module Reports
      class Get835
        class Log < ::Log
          def tag!(tags)
            tags << :stedi
            tags << :healthcare
            tags << :reports
            tags << :get_835
          end
        end
      end
    end
  end
end
