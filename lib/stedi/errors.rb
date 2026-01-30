# frozen_string_literal: true

module Stedi
  class Error < StandardError
    attr_reader :response

    def initialize(message = nil, response: nil)
      @response = response
      super(message)
    end
  end

  class AuthenticationError < Error
    def initialize(message = "Invalid or missing API key", response: nil)
      super
    end
  end

  class ValidationError < Error
    attr_reader :errors

    def initialize(message = "Validation failed", response: nil, errors: [])
      @errors = errors
      super(message, response: response)
    end
  end

  class ApiError < Error
    attr_reader :status

    def initialize(message = "API request failed", response: nil, status: nil)
      @status = status
      super(message, response: response)
    end
  end
end
