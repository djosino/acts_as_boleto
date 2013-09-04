$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "acts_as_boleto/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "acts_as_boleto"
  s.version     = ActsAsBoleto::VERSION
  s.authors     = ["TODO: Danilo Josino"]
  s.email       = ["TODO: danilo.josino@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: ActsAsBoleto para rails4.0.0."
  s.description = "TODO: Geração de boletos do Bradesco para rails4 - ActsAsBoleto."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.0"
end
