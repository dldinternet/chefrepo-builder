require 'twc_cms/builder'
include TWC_CMS::Builder

class GetMakefile < BuilderBase

	# ---------------------------------------------------------------------------------------------------------------
	def run()
		@default_options[:env_keys] = %w(
																			JENKINS_HOME
																			BUILD_NUMBER

																			PROJECT_NAME

																			MAKEFILE_URL
																		)
		if 0 == super
			if 0 == getMakefile()
				if 0 == parseMakefile()
					if 0 == saveMakefile()
						# noop
					end
				end
			end
		end

		@vars[:return_code]
	end

end
