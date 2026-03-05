# frozen_string_literal: true

require_relative "get_835/log"

module Stedi
  module Healthcare
    module Reports
      class Get835
        include Dependency
        include Log::Dependency

        ENDPOINT = "/change/medicalnetwork/reports/v2"

        dependency :session, Stedi::Healthcare::Session

        def self.configure(receiver, session: nil, attr_name: nil)
          attr_name ||= :get_835
          instance = build(session:)
          receiver.public_send("#{attr_name}=", instance)
        end

        def self.build(session: nil)
          instance = new
          instance.configure(session:)
          instance
        end

        def self.call(transaction_id, session: nil)
          instance = build(session:)
          instance.(transaction_id)
        end

        def configure(session: nil)
          Stedi::Healthcare::Session.configure(self, session:, attr_name: :session)
        end

        def call(transaction_id)
          logger.trace { "Fetching 835 report. (Transaction ID: #{transaction_id})" }
          session.(:get, "#{ENDPOINT}/#{transaction_id}/835")
        end

        module Substitute
          class Get835
            attr_reader :calls
            attr_accessor :response
            attr_accessor :error
            attr_accessor :response_proc

            def initialize
              @calls = []
              @response = Response.new({})
            end

            def call(transaction_id)
              @calls << { transaction_id: transaction_id }
              raise error if error

              if response_proc
                response_proc.call(transaction_id, calls.length)
              else
                response
              end
            end
          end

          def self.build
            Get835.new
          end

          def self.configure(receiver, get_835: nil, attr_name: nil)
            attr_name ||= :get_835
            receiver.public_send("#{attr_name}=", get_835 || build)
          end
        end
      end
    end
  end
end
