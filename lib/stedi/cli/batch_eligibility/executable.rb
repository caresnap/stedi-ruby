# frozen_string_literal: true

require_relative "../batch_eligibility"

module Stedi
  module CLI
    module BatchEligibility
      class Executable
        include Dependency

        dependency :runner, Stedi::CLI::BatchEligibility::Runner

        def self.configure(receiver, runner: nil, attr_name: nil)
          attr_name ||= :batch_eligibility_executable
          instance = build(runner:)
          receiver.public_send("#{attr_name}=", instance)
        end

        def self.build(runner: nil)
          instance = new
          instance.configure(runner:)
          instance
        end

        def self.call(argv, stdout: $stdout, stderr: $stderr, env: ENV, runner: nil)
          instance = build(runner:)
          instance.(argv, stdout:, stderr:, env:)
        end

        def configure(runner: nil)
          if runner
            self.runner = runner
          else
            Stedi::CLI::BatchEligibility::Runner.configure(self, attr_name: :runner)
          end
        end

        def call(argv, stdout: $stdout, stderr: $stderr, env: ENV)
          env["LOG_LEVEL"] = "trace"
          env["CONSOLE_DEVICE"] ||= "stderr"
          env["LOG_TAGS"] = "_all"

          runner.(argv, stdout:, stderr:, env:)
        end
      end
    end
  end
end
