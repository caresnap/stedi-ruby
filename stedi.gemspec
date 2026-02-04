# frozen_string_literal: true

require_relative "lib/stedi/version"

Gem::Specification.new do |s|
  s.name = "stedi-ruby"
  s.version = Stedi::VERSION
  s.authors = ["CareSnap"]
  s.email = ["dev@caresnap.com"]

  s.summary = "Ruby client for Stedi Healthcare API"
  s.description = "A Ruby gem for interacting with the Stedi Healthcare API, including 270/271 eligibility checks."
  s.homepage = "https://github.com/caresnap/stedi-ruby"
  s.licenses = ['MIT']
  s.required_ruby_version = ">= 2.7.0"

  s.metadata["homepage_uri"] = s.homepage
  s.metadata["source_code_uri"] = s.homepage
  s.metadata["changelog_uri"] = "#{s.homepage}/blob/main/CHANGELOG.md"

  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  s.require_paths = ["lib"]

  s.add_dependency "faraday", "~> 2.0"
  s.add_dependency "faraday-retry", "~> 2.0"
end
