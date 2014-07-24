require 'twc_cms/builder'
include TWC_CMS::Builder

class DrushMakefile < BuilderBase

	# -------------------------------------------------------------------------------------------------------------------
	def run()
		@default_options[:env_keys] = %w(
																			JENKINS_HOME
																			BUILD_NUMBER

																			PROJECT_NAME

																			AWS_ACCESS_KEY_ID
																			AWS_SECRET_ACCESS_KEY
																			AWS_S3_BUCKET
																		)
		if 0 == super
			if 0 == readMakefile()
				if 0 == parseMakefile()
					if 0 == drushMakefile()
						if 0 == uploadBuildArtifacts()
							# noop
						end
					end
				end
			end
		end

		@vars[:return_code]
	end

end
