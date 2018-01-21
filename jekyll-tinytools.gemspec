
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jekyll/tinytools/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-tinytools"
  spec.version       = Jekyll::TinyTools::VERSION
  spec.required_ruby_version = '>= 2.1.0'
  spec.authors       = ["Alex Ibrado"]
  spec.email         = ["alex@ibrado.org"]

  spec.summary       = %q{12-in-1 tools for Jekyll developers}
  spec.description   = %q{This plugin combines 12 tiny but powerful tools for Jekyll developers}
  spec.homepage      = "https://github.com/ibrado/jekyll-tinytools"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
