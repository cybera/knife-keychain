$:.push File.expand_path("../lib", __FILE__)
require "knife-keychain/version"

Gem::Specification.new do |s|
  s.name        = 'knife-keychain'
  s.version     = Knife::Keychain::VERSION
  s.date        = '2012-07-06'
  s.summary     = "Store keys as encrypted data bag items"
  s.description = "Store keys as encrypted data bag items"
  s.authors     = ["David Ackerman"]
  s.email       = 'david.ackerman@cybera.ca'
  s.homepage    = "https://github.com/cybera/knife-keychain"
  s.files       = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end