# frozen_string_literal: true

require_relative "session/log"

module Stedi
  module Healthcare
    class Session
      include Dependency
      include Log::Dependency

      dependency :http_session, Stedi::HTTP::Session

      def self.configure(receiver, session: nil, attr_name: nil)
        attr_name ||= :session
        instance = session || build
        receiver.public_send("#{attr_name}=", instance)
      end

      def self.build(http_session: nil, api_key: nil)
        instance = new
        instance.configure(http_session:, api_key:)
        instance
      end

      def self.call(method, path, params: nil, body: nil, http_session: nil, api_key: nil)
        instance = build(http_session:, api_key:)
        instance.(method, path, params:, body:)
      end

      def configure(http_session: nil, api_key: nil)
        if http_session
          self.http_session = http_session
        else
          Stedi::HTTP::Session.configure(
            self,
            api_key: api_key || Stedi.api_key,
            api_url: API_URL,
            attr_name: :http_session
          )
        end
      end

      def call(method, path, params: nil, body: nil)
        logger.trace { "Calling healthcare session. (Method: #{method}, Path: #{path})" }
        http_session.(method, path, params:, body:)
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

          def call(method, path, params: nil, body: nil)
            @calls << {
              method: method,
              path: path,
              params: params,
              body: body
            }

            raise error if error

            response
          end
        end

        def self.build
          Session.new
        end

        def self.configure(receiver, session: nil, attr_name: nil)
          attr_name ||= :session
          receiver.public_send("#{attr_name}=", session || build)
        end
      end
    end
  end
end
