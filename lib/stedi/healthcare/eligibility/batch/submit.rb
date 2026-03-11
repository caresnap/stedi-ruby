# frozen_string_literal: true

module Stedi
  module Healthcare
    module Eligibility
      module Batch
        class Submit
          include Dependency
          include Log::Dependency

          ENDPOINT = "/eligibility-manager/batch-eligibility"

          dependency :session, Stedi::Manager::Session

          class Log < ::Log
            def tag!(tags)
              tags << :stedi
              tags << :healthcare
              tags << :eligibility
              tags << :batch
              tags << :submit
            end
          end

          def self.configure(receiver, session: nil, attr_name: nil)
            attr_name ||= :submit_eligibility_batch
            instance = build(session:)
            receiver.public_send("#{attr_name}=", instance)
          end

          def self.build(session: nil)
            instance = new
            instance.configure(session:)
            instance
          end

          def self.call(items, name: nil, max_retry_hours: nil, headers: nil, x_forwarded_for: nil, session: nil)
            instance = build(session:)
            instance.(items, name:, max_retry_hours:, headers:, x_forwarded_for:)
          end

          def configure(session: nil)
            Stedi::Manager::Session.configure(self, session:, attr_name: :session)
          end

          def call(items, name: nil, max_retry_hours: nil, headers: nil, x_forwarded_for: nil)
            body = {
              items: items,
              name: name,
              max_retry_hours: max_retry_hours
            }.reject { |_, value| value.nil? }

            logger.trace { "Submitting eligibility batch." }

            session.(:post, ENDPOINT, body:, headers: build_headers(headers, x_forwarded_for))
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
            class Submit
              attr_reader :calls
              attr_accessor :response
              attr_accessor :error

              def initialize
                @calls = []
                @response = Response.new({})
              end

              def call(items, name: nil, max_retry_hours: nil, headers: nil, x_forwarded_for: nil)
                @calls << {
                  items: items,
                  name: name,
                  max_retry_hours: max_retry_hours,
                  headers: headers,
                  x_forwarded_for: x_forwarded_for
                }

                raise error if error

                response
              end
            end

            def self.build
              Submit.new
            end

            def self.configure(receiver, submit: nil, attr_name: nil)
              attr_name ||= :submit_eligibility_batch
              receiver.public_send("#{attr_name}=", submit || build)
            end
          end
        end
      end
    end
  end
end
