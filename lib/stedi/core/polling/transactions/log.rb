# frozen_string_literal: true

module Stedi
  module Core
    module Polling
      class Transactions
        class Log < ::Log
          def tag!(tags)
            tags << :stedi
            tags << :core
            tags << :polling
            tags << :transactions
          end
        end
      end
    end
  end
end
