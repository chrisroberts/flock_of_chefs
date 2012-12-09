$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'flock_of_chefs/version'

Gem::Specification.new do |s|
  s.name = 'flock_of_chefs'
  s.version = FlockOfChefs::VERSION.version
  s.summary = 'Flock of chefs'
  s.author = 'Chris Roberts'
  s.email = 'chrisroberts.code@gmail.com'
  s.homepage = 'http://github.com/chrisroberts/flock_of_chefs'
  s.description = 'Chefs flocking about'
  s.require_path = 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.md']  
  s.files = Dir['**/*']
  s.add_dependency 'chef'
  s.add_dependency 'cr-dcell'
  s.add_dependency 'zk'
end
