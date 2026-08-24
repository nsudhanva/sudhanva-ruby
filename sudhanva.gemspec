# frozen_string_literal: true

require_relative "lib/sudhanva/version"

Gem::Specification.new do |spec|
  spec.name = "sudhanva"
  spec.version = Sudhanva::VERSION
  spec.authors = ["Sudhanva Narayana"]
  spec.email = ["nsudhanva@gmail.com"]
  spec.summary = "Minimal Ruby client for the public sudhanva.me API."
  spec.description = "A dependency-free client for published profile data, articles, search, batch reads, and profile-insight jobs."
  spec.homepage = "https://sudhanva.me"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "homepage_uri" => "https://sudhanva.me",
    "source_code_uri" => "https://github.com/nsudhanva/sudhanva-ruby",
    "documentation_uri" => "https://sudhanva.me/developers/sdks/",
    "bug_tracker_uri" => "https://github.com/nsudhanva/sudhanva-ruby/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]
end
