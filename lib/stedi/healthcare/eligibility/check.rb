# frozen_string_literal: true

require_relative "check/log"

module Stedi
  module Healthcare
    module Eligibility
      class Check
        include Dependency
        include Log::Dependency

        ENDPOINT = "/change/medicalnetwork/eligibility/v3"

        dependency :session, Stedi::Healthcare::Session

        def self.configure(receiver, session: nil, attr_name: nil)
          attr_name ||= :check_eligibility
          instance = build(session:)
          receiver.public_send("#{attr_name}=", instance)
        end

        def self.build(session: nil)
          instance = new
          instance.configure(session:)
          instance
        end

        def self.call(params, headers: nil, x_forwarded_for: nil, session: nil)
          instance = build(session:)
          instance.(params, headers:, x_forwarded_for:)
        end

        def configure(session: nil)
          Stedi::Healthcare::Session.configure(self, session:, attr_name: :session)
        end

        def call(params, headers: nil, x_forwarded_for: nil)
          logger.trace { "Checking eligibility." }
          session.(:post, ENDPOINT, body: params, headers: build_headers(headers, x_forwarded_for))
        end

        private

        def build_headers(headers, x_forwarded_for)
          request_headers = headers ? headers.dup : {}
          forwarded_for = normalize_x_forwarded_for(x_forwarded_for)
          request_headers["X-Forwarded-For"] = forwarded_for if forwarded_for
          request_headers.empty? ? nil : request_headers
        end

        def normalize_x_forwarded_for(x_forwarded_for)
          return nil if x_forwarded_for.nil?
          return x_forwarded_for.join(", ") if x_forwarded_for.is_a?(Array)

          x_forwarded_for.to_s
        end

        module Substitute
          class Check
            attr_reader :calls
            attr_accessor :response
            attr_accessor :error

            def initialize
              @calls = []
              @response = Response.new({})
            end

            def call(params, headers: nil, x_forwarded_for: nil)
              @calls << {
                params: params,
                headers: headers,
                x_forwarded_for: x_forwarded_for
              }
              raise error if error
              response
            end
          end

          def self.build
            Check.new
          end

          def self.configure(receiver, check: nil, attr_name: nil)
            attr_name ||= :check_eligibility
            receiver.public_send("#{attr_name}=", check || build)
          end
        end
      end
    end
  end
end
