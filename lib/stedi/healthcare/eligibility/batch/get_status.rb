# frozen_string_literal: true

module Stedi
  module Healthcare
    module Eligibility
      module Batch
        class GetStatus
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
              tags << :get_status
            end
          end

          def self.configure(receiver, session: nil, attr_name: nil)
            attr_name ||= :get_eligibility_batch_status
            instance = build(session:)
            receiver.public_send("#{attr_name}=", instance)
          end

          def self.build(session: nil)
            instance = new
            instance.configure(session:)
            instance
          end

          def self.call(batch_id, headers: nil, session: nil)
            instance = build(session:)
            instance.(batch_id, headers:)
          end

          def configure(session: nil)
            Stedi::Manager::Session.configure(self, session:, attr_name: :session)
          end

          def call(batch_id, headers: nil)
            logger.trace { "Fetching eligibility batch status. (Batch ID: #{batch_id})" }
            session.(:get, "#{ENDPOINT}/#{batch_id}", headers:)
          end

          module Substitute
            class GetStatus
              attr_reader :calls
              attr_accessor :response
              attr_accessor :error

              def initialize
                @calls = []
                @response = Response.new({})
              end

              def call(batch_id, headers: nil)
                @calls << {
                  batch_id: batch_id,
                  headers: headers
                }

                raise error if error

                response
              end
            end

            def self.build
              GetStatus.new
            end

            def self.configure(receiver, get_status: nil, attr_name: nil)
              attr_name ||= :get_eligibility_batch_status
              receiver.public_send("#{attr_name}=", get_status || build)
            end
          end
        end
      end
    end
  end
end
