# frozen_string_literal: true

require "dependency"
require "log"

require_relative "stedi/version"
require_relative "stedi/errors"
require_relative "stedi/response"
require_relative "stedi/http/session"
require_relative "stedi/core"
require_relative "stedi/manager"
require_relative "stedi/healthcare"

module Stedi
  class << self
    attr_accessor :api_key

    def configure
      yield(self)
    end

    def reset!
      @api_key = nil
    end
  end
end
