$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sprite_map/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sprite_map"
  s.version     = SpriteMap::VERSION
  s.authors     = ["Aleck Greenham"]
  s.email       = ["greenhama13@gmail.com"]
  s.homepage    = "https://github.com/greena13/sprite_map"
  s.summary     = "Rails engine for generating dynamic sprite maps"
  s.description = "Generate sprites from images at runtime, to cache and speed up subsequent requests"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "paperclip", ">= 4.2", "< 6.0"

  s.add_development_dependency "sqlite3", "~> 0"
end
