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

        def self.call(params, session: nil)
          instance = build(session:)
          instance.(params)
        end

        def configure(session: nil)
          Stedi::Healthcare::Session.configure(self, session:, attr_name: :session)
        end

        def call(params)
          logger.trace { "Checking eligibility." }
          session.(:post, ENDPOINT, body: params)
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

            def call(params)
              @calls << { params: params }
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
