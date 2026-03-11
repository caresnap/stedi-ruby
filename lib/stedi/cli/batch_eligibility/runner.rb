# frozen_string_literal: true

require "json"
require "optparse"
require "pathname"

module Stedi
  module CLI
    module BatchEligibility
      class Runner
        Error = Class.new(StandardError)

        include Dependency

        dependency :load_csv, Stedi::CLI::BatchEligibility::LoadCSV
        dependency :submit_batch, Stedi::Healthcare::Eligibility::Batch::Submit
        dependency :get_batch_status, Stedi::Healthcare::Eligibility::Batch::GetStatus
        dependency :get_batch_items, Stedi::Healthcare::Eligibility::Batch::GetItemStatuses
        dependency :poll_batch, Stedi::Healthcare::Eligibility::Batch::Poll

        def self.configure(receiver, load_csv: nil, submit_batch: nil, get_batch_status: nil, get_batch_items: nil, poll_batch: nil, attr_name: nil)
          attr_name ||= :batch_eligibility_runner
          instance = build(
            load_csv:,
            submit_batch:,
            get_batch_status:,
            get_batch_items:,
            poll_batch:
          )
          receiver.public_send("#{attr_name}=", instance)
        end

        def self.build(load_csv: nil, submit_batch: nil, get_batch_status: nil, get_batch_items: nil, poll_batch: nil)
          instance = new
          instance.configure(
            load_csv:,
            submit_batch:,
            get_batch_status:,
            get_batch_items:,
            poll_batch:
          )
          instance
        end

        def self.call(argv, stdout: $stdout, stderr: $stderr, env: ENV, load_csv: nil, submit_batch: nil, get_batch_status: nil, get_batch_items: nil, poll_batch: nil)
          instance = build(
            load_csv:,
            submit_batch:,
            get_batch_status:,
            get_batch_items:,
            poll_batch:
          )
          instance.(argv, stdout:, stderr:, env:)
        end

        def configure(load_csv: nil, submit_batch: nil, get_batch_status: nil, get_batch_items: nil, poll_batch: nil)
          self.load_csv = load_csv || Stedi::CLI::BatchEligibility::LoadCSV
          self.submit_batch = submit_batch || Stedi::Healthcare::Eligibility::Batch::Submit
          self.get_batch_status = get_batch_status || Stedi::Healthcare::Eligibility::Batch::GetStatus
          self.get_batch_items = get_batch_items || Stedi::Healthcare::Eligibility::Batch::GetItemStatuses
          self.poll_batch = poll_batch || Stedi::Healthcare::Eligibility::Batch::Poll
        end

        def call(argv, stdout: $stdout, stderr: $stderr, env: ENV)
          options = parse_options(argv.dup)
          csv_path = resolve_csv_path(options[:csv_path])

          configure_api_key(env)

          response = case options[:mode]
                     when :submit
                       submit(csv_path)
                     when :status
                       get_batch_status.(read_batch_id(csv_path))
                     when :item_statuses
                       get_batch_items.(read_batch_id(csv_path))
                     when :poll
                       poll_batch.(nil, batch_id: read_batch_id(csv_path))
                     end

          stdout.puts(JSON.pretty_generate(response.to_h))
          0
        rescue Error, ArgumentError, Errno::ENOENT, OptionParser::ParseError => error
          stderr.puts(error.message)
          1
        end

        private

        def parse_options(argv)
          flags = []
          options = { mode: :submit }

          parser = OptionParser.new
          parser.on("--status") { flags << :status }
          parser.on("--item-statuses") { flags << :item_statuses }
          parser.on("--poll") { flags << :poll }

          remaining = parser.parse(argv)

          if flags.length > 1
            raise Error, "Choose only one of --status, --item-statuses, or --poll"
          end

          if remaining.length != 1
            raise Error, "Provide exactly one CSV file path"
          end

          options[:mode] = flags.first unless flags.empty?
          options[:csv_path] = remaining.first
          options
        end

        def resolve_csv_path(csv_path)
          path = Pathname(csv_path).expand_path
          raise Error, "CSV file not found: #{path}" unless path.file?

          path
        end

        def configure_api_key(env)
          api_key = env["STEDI_API_KEY"]
          raise Error, "Set STEDI_API_KEY before running this command" if api_key.to_s.empty?

          Stedi.api_key = api_key
        end

        def submit(csv_path)
          items = load_csv.(csv_path.to_s)
          response = submit_batch.(items, name: batch_name(csv_path))
          write_batch_id(csv_path, response.batch_id)
          response
        end

        def batch_name(csv_path)
          csv_path.basename(csv_path.extname).to_s
        end

        def batch_id_path(csv_path)
          csv_path.sub_ext(".batch_id")
        end

        def write_batch_id(csv_path, batch_id)
          if batch_id.to_s.empty?
            raise Error, "Batch submit response did not include batch_id"
          end

          File.write(batch_id_path(csv_path), "#{batch_id}\n")
        end

        def read_batch_id(csv_path)
          path = batch_id_path(csv_path)
          raise Error, "Batch ID sidecar not found: #{path}. Submit the CSV first." unless path.file?

          batch_id = path.read.strip
          raise Error, "Batch ID sidecar is empty: #{path}" if batch_id.empty?

          batch_id
        end

        module Substitute
          class Runner
            attr_reader :calls
            attr_accessor :exit_code
            attr_accessor :error

            def initialize
              @calls = []
              @exit_code = 0
            end

            def call(argv, stdout: $stdout, stderr: $stderr, env: ENV)
              @calls << {
                argv: argv,
                stdout: stdout,
                stderr: stderr,
                env: env
              }

              raise error if error

              exit_code
            end
          end

          def self.build
            Runner.new
          end

          def self.configure(receiver, runner: nil, attr_name: nil)
            attr_name ||= :batch_eligibility_runner
            receiver.public_send("#{attr_name}=", runner || build)
          end
        end
      end
    end
  end
end
