# -*- encoding: utf-8 -*-

require File.expand_path('lib/cicd/builder/chefrepo/version', File.dirname(__FILE__))

Gem::Specification.new do |gem|
  gem.name          = 'chefrepo-builder'
  gem.version       = CiCd::Builder::VERSION
  gem.summary       = 'Jenkins builder task for CI/CD'
  gem.description   = 'Jenkins builder task for CI/CD'
  gem.license       = 'Apachev2'
  gem.authors       = ['Christo De Lange']
  gem.email         = 'rubygems@dldinternet.com'
  gem.homepage      = 'https://rubygems.org/gems/chefrepo-builder'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'awesome_print', ">= 0.0.0"
  gem.add_dependency 'inifile', '>= 0.0.0'
  gem.add_dependency 'logging', '>= 0.0.0'
  gem.add_dependency 'json', '= 1.7.7'
  gem.add_dependency 'chef', '>= 11.8.2'
  gem.add_dependency 'aws-sdk', '>= 0.0.0'
  gem.add_dependency 'yajl-ruby', '>= 0.0.0'
  
  gem.add_development_dependency 'bundler', '~> 1.0'
  gem.add_development_dependency 'rake', '~> 0.8'
  gem.add_development_dependency 'rubygems-tasks', '~> 0.2'
  gem.add_development_dependency 'cucumber'
end
