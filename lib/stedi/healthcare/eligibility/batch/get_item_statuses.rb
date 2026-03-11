# frozen_string_literal: true

module Stedi
  module Healthcare
    module Eligibility
      module Batch
        class GetItemStatuses
          include Dependency
          include Log::Dependency

          ENDPOINT = "/eligibility-manager/batch"

          dependency :session, Stedi::Manager::Session

          class Log < ::Log
            def tag!(tags)
              tags << :stedi
              tags << :healthcare
              tags << :eligibility
              tags << :batch
              tags << :get_item_statuses
            end
          end

          def self.configure(receiver, session: nil, attr_name: nil)
            attr_name ||= :get_eligibility_batch_item_statuses
            instance = build(session:)
            receiver.public_send("#{attr_name}=", instance)
          end

          def self.build(session: nil)
            instance = new
            instance.configure(session:)
            instance
          end

          def self.call(batch_id, page_token: nil, page_size: nil, state: nil, headers: nil, session: nil)
            instance = build(session:)
            instance.(batch_id, page_token:, page_size:, state:, headers:)
          end

          def configure(session: nil)
            Stedi::Manager::Session.configure(self, session:, attr_name: :session)
          end

          def call(batch_id, page_token: nil, page_size: nil, state: nil, headers: nil)
            params = {
              page_token: page_token,
              page_size: page_size,
              state: state
            }.reject { |_, value| value.nil? }

            logger.trace { "Fetching eligibility batch item statuses. (Batch ID: #{batch_id})" }

            session.(:get, "#{ENDPOINT}/#{batch_id}/items", params:, headers:)
          end

          module Substitute
            class GetItemStatuses
              attr_reader :calls
              attr_accessor :response
              attr_accessor :error

              def initialize
                @calls = []
                @response = Response.new({ "items" => [] })
              end

              def call(batch_id, page_token: nil, page_size: nil, state: nil, headers: nil)
                @calls << {
                  batch_id: batch_id,
                  page_token: page_token,
                  page_size: page_size,
                  state: state,
                  headers: headers
                }

                raise error if error

                response
              end
            end

            def self.build
              GetItemStatuses.new
            end

            def self.configure(receiver, get_item_statuses: nil, attr_name: nil)
              attr_name ||= :get_eligibility_batch_item_statuses
              receiver.public_send("#{attr_name}=", get_item_statuses || build)
            end
          end
        end
      end
    end
  end
end
