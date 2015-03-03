# -*- encoding: utf-8 -*-

require File.expand_path('lib/cicd/builder/chefrepo/version', File.dirname(__FILE__))

Gem::Specification.new do |gem|
  gem.name          = 'chefrepo-builder'
  gem.version       = CiCd::Builder::ChefRepo::VERSION
  gem.summary       = 'Jenkins builder task for Chef repo CI/CD'
  gem.description   = 'Jenkins builder task for Chef repository for Continuous Integration/Continuous Delivery artifact promotion style deployments'
  gem.license       = 'Apachev2'
  gem.authors       = ['Christo De Lange']
  gem.email         = 'rubygems@dldinternet.com'
  gem.homepage      = 'https://rubygems.org/gems/chefrepo-builder'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'cicd-builder', '>= 0.9.32', '< 1.1'
  gem.add_dependency 'json', '= 1.8.1'

  gem.add_development_dependency 'bundler', '>= 1.6', '< 1.7'
  gem.add_development_dependency 'rake', '>= 10.3', '< 11'
  gem.add_development_dependency 'rubygems-tasks', '>= 0.2', '< 1.1'
  gem.add_development_dependency 'cucumber', '>= 0.10.7', '< 0.11'
end
