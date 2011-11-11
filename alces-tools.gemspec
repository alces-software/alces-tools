$:.push File.expand_path("../lib", __FILE__)
require 'alces-tools/version'

Gem::Specification.new do |s|
  s.name = 'alces-tools'
  s.version = Alces::Tools::VERSION
  s.platform = Gem::Platform::RUBY
  s.date = '2011-11-10'
  s.authors = ['Stephen F. Norledge', 'Mark J. Titorenko']
  s.email = 'mark.titorenko@alces-software.com'
  s.homepage = 'http://github.com/alces-software/alces-tools'
  s.summary = %Q{Base utility and tool classes to support Alces utilities}
  s.description = %Q{Base utility and tool classes to support Alces utilities}
  s.extra_rdoc_files = [
    'LICENSE.txt',
    'README.rdoc',
  ]

  s.required_rubygems_version = Gem::Requirement.new('>= 1.3.7')
  s.rubygems_version = '1.3.7'
  s.specification_version = 3

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'bueller'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rcov'
end

