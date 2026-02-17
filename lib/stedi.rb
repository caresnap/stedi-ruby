# frozen_string_literal: true

require_relative "stedi/version"
require_relative "stedi/errors"
require_relative "stedi/response"
require_relative "stedi/client"
require_relative "stedi/core"
require_relative "stedi/healthcare"

module Stedi
  class << self
    attr_accessor :api_key

    def configure
      yield(self)
    end

    def healthcare
      @healthcare ||= Healthcare::Client.new
    end

    def core
      @core ||= Core::Client.new
    end

    def reset!
      @api_key = nil
      @healthcare = nil
      @core = nil
    end
  end
end
