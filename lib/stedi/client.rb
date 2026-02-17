# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"
require "uri"

module Stedi
  class Client
    def initialize(api_key: nil, api_url: nil)
      @api_key = api_key || Stedi.api_key
      @api_url = api_url
    end

    def get(path, params = {})
      response = connection.get(build_path(path)) do |req|
        req.params = camelize_keys(params)
      end

      handle_response(response)
    end

    def post(path, body)
      response = connection.post(build_path(path)) do |req|
        req.body = JSON.generate(camelize_keys(body))
      end

      handle_response(response)
    end

    private

    def connection
      @connection ||= Faraday.new(url: @api_url) do |f|
        f.request :retry, {
          max: 3,
          interval: 0.5,
          interval_randomness: 0.5,
          backoff_factor: 2,
          retry_statuses: [429, 500, 502, 503, 504]
        }
        f.headers["Authorization"] = @api_key
        f.headers["Content-Type"] = "application/json"
        f.headers["Accept"] = "application/json"
        f.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      body = parse_body(response.body)

      case response.status
      when 200..299
        Response.new(body)
      when 401, 403
        raise AuthenticationError.new(
          body["message"] || "Authentication failed",
          response: body
        )
      when 400, 422
        raise ValidationError.new(
          body["message"] || "Validation failed",
          response: body,
          errors: body["errors"] || []
        )
      else
        raise ApiError.new(
          body["message"] || "API request failed",
          response: body,
          status: response.status
        )
      end
    end

    def parse_body(body)
      return {} if body.nil? || body.empty?
      JSON.parse(body)
    rescue JSON::ParserError
      { "message" => body }
    end

    def camelize_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(key, value), result|
          camelized_key = camelize(key.to_s)
          result[camelized_key] = camelize_keys(value)
        end
      when Array
        obj.map { |v| camelize_keys(v) }
      else
        obj
      end
    end

    def camelize(str)
      str.split("_").each_with_index.map do |word, index|
        index.zero? ? word : word.capitalize
      end.join
    end

    def build_path(path)
      # Extract path from api_url and join with request path
      base_uri = URI.parse(@api_url)
      base_path = base_uri.path.chomp("/")
      request_path = path.start_with?("/") ? path : "/#{path}"
      "#{base_path}#{request_path}"
    end

    module Substitute
      class Client
        attr_reader :gets
        attr_reader :posts
        attr_accessor :response_body, :response_status

        def initialize
          @gets = []
          @posts = []
          @response_body = {}
          @response_status = 200
        end

        def get(path, params = {})
          @gets << { path: path, params: params }
          handle_response
        end

        def post(path, body)
          @posts << { path: path, body: body }
          handle_response
        end

        def got?(path: nil, params: nil)
          @gets.any? do |get|
            (path.nil? || get[:path] == path) &&
              (params.nil? || get[:params] == params)
          end
        end

        def posted?(path: nil, body: nil)
          @posts.any? do |post|
            (path.nil? || post[:path] == path) &&
              (body.nil? || post[:body] == body)
          end
        end

        def last_get
          @gets.last
        end

        def last_post
          @posts.last
        end

        private

        def handle_response
          case @response_status
          when 200..299
            Response.new(@response_body)
          when 401, 403
            raise AuthenticationError.new(
              @response_body["message"] || "Authentication failed",
              response: @response_body
            )
          when 400, 422
            raise ValidationError.new(
              @response_body["message"] || "Validation failed",
              response: @response_body,
              errors: @response_body["errors"] || []
            )
          else
            raise ApiError.new(
              @response_body["message"] || "API request failed",
              response: @response_body,
              status: @response_status
            )
          end
        end
      end

      def self.build
        Client.new
      end
    end
  end
end
