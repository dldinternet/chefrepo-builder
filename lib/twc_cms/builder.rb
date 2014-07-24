module TWC_CMS
	module Builder

		require 'awesome_print'
		require 'optparse'
		require 'inifile'
		require 'logging'
		require 'net/http'
		require 'uri'
		require 'fileutils'
		require 'digest'
		require 'yajl/json_gem'
		require 'aws-sdk'

		_lib=File.dirname(__FILE__)
		$:.unshift(_lib) unless $:.include?(_lib)

		require 'twc_cms/builder/version'
		require 'twc_cms/builder/mixlib/constants'

		#noinspection ALL
		class BuilderBase
			attr_accessor :default_options
			attr_accessor :options
			attr_accessor :logger
			attr_accessor :vars

			def initialize()
				@default_options = {
						builder:        ::TWC_CMS::Builder::VERSION,
						env_keys:       %w(JENKINS_HOME BUILD_NUMBER)
				}
			end

			require 'twc_cms/builder/mixlib/errors'
			require 'twc_cms/builder/mixlib/utils'
			require 'twc_cms/builder/mixlib/options'
			require 'twc_cms/builder/mixlib/environment'
			require 'twc_cms/builder/mixlib/makefile'
			require 'twc_cms/builder/mixlib/repo'
			require 'twc_cms/builder/mixlib/build'

			# ---------------------------------------------------------------------------------------------------------------
			def run()
				$stdout.write("TWC_CMS::Builder v#{::TWC_CMS::Builder::VERSION}\n")
				parseOptions()

				ret = checkEnvironment()
				if 0 == ret
					ret = getVars()
				end
				ret
			end

		end

	end
end