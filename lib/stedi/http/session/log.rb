# frozen_string_literal: true

module Stedi
  module HTTP
    class Session
      class Log < ::Log
        def tag!(tags)
          tags << :stedi
          tags << :http
          tags << :session
        end
      end
    end
  end
end
