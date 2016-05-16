# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'za_bank_scraper/version'

Gem::Specification.new do |spec|
  spec.name          = "za_bank_scraper"
  spec.version       = ZaBankScraper::VERSION
  spec.authors       = ["Jeffrey van Aswegen"]
  spec.email         = ["jeffmess@gmail.com"]

  spec.summary       = %q{Scrapes South African Bank website for ofx statements (ABSA, STD Bank, FNB).}
  spec.homepage      = "http://github.com/jeffmess/za_bank_scraper"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.add_dependency "nokogiri", "1.5.5"
  spec.add_dependency "mechanize", "2.7.3"
  spec.add_dependency "text-table"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
end
