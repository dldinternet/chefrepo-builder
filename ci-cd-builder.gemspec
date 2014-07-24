
require File.dirname(__FILE__) + '/lib/twc_cms/builder/version'
Gem::Specification.new do |s|
	s.name = "ci-cd-builder"
	s.version = ::TWC_CMS::Builder::VERSION
	s.platform    = Gem::Platform::RUBY
	s.rubygems_version = "2.1.5"
	s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
	s.authors = ["Christo De Lange"]
	s.date = "2014-01-02"
	s.description = "Jenkins builder task for CI/CD"
	s.email = "rubygems@dldinternet.com"
	s.executables = %w()
	s.extra_rdoc_files = []
	s.require_path = 'lib'
	# If you need to check in files that aren't .rb files, add them here
	s.files        = Dir[ "{lib}/**/*.rb",
                        'bin/*',
                        'Gemfile',
                        'VERSION',
											]
	s.homepage = 'http://github.com/dldinternet/ci-cd-builder'
	s.licenses = ['MIT']
	s.require_paths = ['lib']
	s.summary = "Jenkins builder task for CI/CD"

	# If you have other dependencies, add them here
	s.add_dependency 'awesome_print', ">= 0.0.0"
	s.add_dependency 'inifile', '>= 0.0.0'
	s.add_dependency 'logging', '>= 0.0.0'
	s.add_dependency 'json', '= 1.7.7'
	s.add_dependency 'chef', '>= 11.8.2'
	s.add_dependency 'aws-sdk', '>= 0.0.0'
	s.add_dependency 'yajl-ruby', '>= 0.0.0'
end
