# frozen_string_literal: true

require "date"

module Stedi
  module Healthcare
    module Eligibility
      module Batch
        class Poll
          include Dependency
          include Log::Dependency

          ENDPOINT = "/eligibility-manager/polling/batch-eligibility"

          dependency :session, Stedi::Manager::Session

          class Log < ::Log
            def tag!(tags)
              tags << :stedi
              tags << :healthcare
              tags << :eligibility
              tags << :batch
              tags << :poll
            end
          end

          def self.configure(receiver, session: nil, attr_name: nil)
            attr_name ||= :poll_eligibility_batch
            instance = build(session:)
            receiver.public_send("#{attr_name}=", instance)
          end

          def self.build(session: nil)
            instance = new
            instance.configure(session:)
            instance
          end

          def self.call(start_date_time = nil, batch_id: nil, page_token: nil, page_size: nil, headers: nil, session: nil)
            instance = build(session:)
            instance.(start_date_time, batch_id:, page_token:, page_size:, headers:)
          end

          def configure(session: nil)
            Stedi::Manager::Session.configure(self, session:, attr_name: :session)
          end

          def call(start_date_time = nil, batch_id: nil, page_token: nil, page_size: nil, headers: nil)
            validate_required_polling_params(start_date_time, batch_id, page_token)

            params = {
              batch_id: batch_id,
              page_token: page_token,
              page_size: page_size,
              start_date_time: normalize_start_date_time(start_date_time)
            }.reject { |_, value| value.nil? }

            logger.trace { "Polling eligibility batch results. (Params: #{params})" }

            session.(:get, ENDPOINT, params:, headers: build_headers(headers, page_size))
          end

          private

          def validate_required_polling_params(start_date_time, batch_id, page_token)
            return if start_date_time || batch_id || page_token

            raise ArgumentError, "Provide batch_id, start_date_time, or page_token"
          end

          def normalize_start_date_time(start_date_time)
            return nil if start_date_time.nil?
            return start_date_time if start_date_time.is_a?(String)
            return start_date_time.iso8601 if start_date_time.respond_to?(:iso8601)

            start_date_time.to_s
          end

          def build_headers(headers, page_size)
            request_headers = headers ? headers.dup : {}
            if page_size && page_size > 20 && !accept_encoding_header?(request_headers)
              request_headers["Accept-Encoding"] = "gzip"
            end
            request_headers.empty? ? nil : request_headers
          end

          def accept_encoding_header?(headers)
            headers.keys.any? { |key| key.to_s.tr("_", "-").casecmp("Accept-Encoding").zero? }
          end

          module Substitute
            class Poll
              attr_reader :calls
              attr_accessor :response
              attr_accessor :error

              def initialize
                @calls = []
                @response = Response.new({ "items" => [] })
              end

              def call(start_date_time = nil, batch_id: nil, page_token: nil, page_size: nil, headers: nil)
                @calls << {
                  start_date_time: start_date_time,
                  batch_id: batch_id,
                  page_token: page_token,
                  page_size: page_size,
                  headers: headers
                }

                raise error if error

                response
              end
            end

            def self.build
              Poll.new
            end

            def self.configure(receiver, poll: nil, attr_name: nil)
              attr_name ||= :poll_eligibility_batch
              receiver.public_send("#{attr_name}=", poll || build)
            end
          end
        end
      end
    end
  end
end
