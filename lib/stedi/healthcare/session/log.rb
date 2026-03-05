# frozen_string_literal: true

module Stedi
  module Healthcare
    class Session
      class Log < ::Log
        def tag!(tags)
          tags << :stedi
          tags << :healthcare
          tags << :session
        end
      end
    end
  end
end
