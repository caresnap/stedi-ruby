# frozen_string_literal: true

require_relative "lib/stedi/version"

Gem::Specification.new do |spec|
  spec.name = "stedi"
  spec.version = Stedi::VERSION
  spec.authors = ["CareSnap"]
  spec.email = ["dev@caresnap.com"]

  spec.summary = "Ruby client for Stedi Healthcare API"
  spec.description = "A Ruby gem for interacting with the Stedi Healthcare API, including 270/271 eligibility checks."
  spec.homepage = "https://github.com/caresnap/stedi-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"
end
