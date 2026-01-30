# frozen_string_literal: true

require_relative "stedi/version"
require_relative "stedi/errors"
require_relative "stedi/response"
require_relative "stedi/client"
require_relative "stedi/healthcare"

module Stedi
  class << self
    attr_accessor :api_key
    attr_writer :base_url

    def configure
      yield(self)
    end

    def base_url
      @base_url ||= "https://healthcare.us.stedi.com/2024-04-01"
    end

    def healthcare
      @healthcare ||= Healthcare::Client.new
    end

    def reset!
      @api_key = nil
      @base_url = nil
      @healthcare = nil
    end
  end
end
