# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  # evt-* dependencies emit noisy Ruby warnings on 3.4; keep default test output focused.
  t.warning = false
end

task default: :test
