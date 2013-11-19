$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "acts_as_boleto/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "acts_as_boleto"
  s.version     = ActsAsBoleto::VERSION
  s.authors     = ["Danilo Josino"]
  s.email       = ["danilo.josino@gmail.com"]
  s.homepage    = ""
  s.summary     = "ActsAsBoleto para rails4."
  s.description = %q{Geração de boletos do Bradesco para rails4 - ActsAsBoleto}
  s.summary       = s.description 

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]
  s.add_dependency "rails", "~> 4.0.0"
  s.add_dependency "barby", "~> 0.5.1"
  s.add_dependency "prawn", "~> 0.12.0"
end
