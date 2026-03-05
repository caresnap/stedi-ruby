# frozen_string_literal: true

module Stedi
  module Core
    class Session
      class Log < ::Log
        def tag!(tags)
          tags << :stedi
          tags << :core
          tags << :session
        end
      end
    end
  end
end
