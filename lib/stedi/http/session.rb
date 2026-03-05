# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"
require "uri"
require_relative "session/log"

module Stedi
  module HTTP
    class Session
      include Dependency
      include Log::Dependency

      attr_accessor :api_key
      attr_accessor :api_url
      attr_writer :connection

      def self.configure(receiver, api_key: nil, api_url: nil, session: nil, attr_name: nil)
        attr_name ||= :http_session
        instance = session || build(api_key:, api_url:)
        receiver.public_send("#{attr_name}=", instance)
      end

      def self.build(api_key: nil, api_url: nil, connection: nil)
        instance = new(api_key:, api_url:)
        instance.connection = connection if connection
        instance
      end

      def self.call(method, path, params: nil, body: nil, headers: nil, api_key: nil, api_url: nil, connection: nil)
        instance = build(api_key:, api_url:, connection:)
        instance.(method, path, params:, body:, headers:)
      end

      def initialize(api_key: nil, api_url: nil)
        @api_key = api_key || Stedi.api_key
        @api_url = api_url
      end

      def call(method, path, params: nil, body: nil, headers: nil)
        logger.trace { "Executing HTTP request. (Method: #{method}, Path: #{path})" }

        response = connection.public_send(method.to_sym, build_path(path)) do |request|
          request.params = camelize_keys(params) if params
          request.headers.update(normalize_headers(headers)) if headers
          request.body = JSON.generate(camelize_keys(body)) unless body.nil?
        end

        logger.debug { "Executed HTTP request. (Method: #{method}, Path: #{path}, Status: #{response.status})" }

        handle_response(response)
      rescue StandardError => error
        logger.error { "HTTP request failed. (Method: #{method}, Path: #{path}, Error: #{error.class}: #{error.message})" }
        raise
      end

      def connection
        @connection ||= Faraday.new(url: api_url) do |f|
          f.request :retry, {
            max: 3,
            interval: 0.5,
            interval_randomness: 0.5,
            backoff_factor: 2,
            retry_statuses: [429, 500, 502, 503, 504]
          }
          f.headers["Authorization"] = api_key
          f.headers["Content-Type"] = "application/json"
          f.headers["Accept"] = "application/json"
          f.adapter Faraday.default_adapter
        end
      end

      private

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
            result[camelize(key.to_s)] = camelize_keys(value)
          end
        when Array
          obj.map { |value| camelize_keys(value) }
        else
          obj
        end
      end

      def camelize(str)
        str.split("_").each_with_index.map do |word, index|
          index.zero? ? word : word.capitalize
        end.join
      end

      def normalize_headers(headers)
        headers.each_with_object({}) do |(key, value), result|
          result[normalize_header_name(key)] = value
        end
      end

      def normalize_header_name(key)
        header_name = key.to_s
        return header_name if header_name.match?(/[A-Z]/) || header_name.include?("-")

        header_name.split("_").map(&:capitalize).join("-")
      end

      def build_path(path)
        base_uri = URI.parse(api_url)
        base_path = base_uri.path.chomp("/")
        request_path = path.start_with?("/") ? path : "/#{path}"
        "#{base_path}#{request_path}"
      end

      module Substitute
        class Session
          attr_reader :calls
          attr_accessor :response
          attr_accessor :error

          def initialize
            @calls = []
            @response = Response.new({})
          end

          def call(method, path, params: nil, body: nil, headers: nil)
            @calls << {
              method: method,
              path: path,
              params: params,
              body: body,
              headers: headers
            }

            raise error if error

            response
          end
        end

        def self.build
          Session.new
        end

        def self.configure(receiver, session: nil, attr_name: nil)
          attr_name ||= :http_session
          receiver.public_send("#{attr_name}=", session || build)
        end
      end
    end
  end
end
