module TWC_CMS
	module Builder

		# ---------------------------------------------------------------------------------------------------------------
		def checkEnvironment()
			# [2013-12-30 Christo] Detect CI ...
			unless ENV.has_key?('JENKINS_HOME')
				puts "Sorry, your CI environment is not supported at this time (2013-12-30) ... Christo De Lange"
				puts "This script is developed for Jenkins so either you are not using Jenkins or you ran me outside of the CI ecosystem ..."
				return 99
			end

			# Check for the necessary environment variables
			map_keys = {}

			@options[:env_keys].each { |k|
				map_keys[k]= (not ENV.has_key?(k))
			}
			missing = map_keys.keys.select{ |k| map_keys[k] }

			if missing.count() > 0
				ap missing
				raise Exception.new("Need environment variables: #{missing}")
			end
			0
		end

		# ---------------------------------------------------------------------------------------------------------------
		def getVars()
			@vars               = {}
			@vars[:release]     = 'latest'
			@vars[:uri_path]    = ''
			@vars[:usercontent] = '/tmp'
			@vars[:variant]     = 'snapshot'
			@vars[:version_ini] = 'sites/default/_version.ini'

			if ENV.has_key?(PROJECT_NAME)
				@vars[:project_name] = ENV[PROJECT_NAME]
			end

			if ENV.has_key?(MAKEFILE_REL)
				@vars[:release] = ENV[MAKEFILE_REL]
			end
			if @vars[:release] != 'latest'
				@vars[:uri_path] = "/#{@vars[:release]}"
			end

			if ENV.has_key?(WORKSPACE)
				@vars[:usercontent] = "#{ENV[WORKSPACE]}"
			end

			if ENV.has_key?(MAKEFILE_LOC)
				@vars[:usercontent] = "#{ENV[MAKEFILE_LOC]}"
			end

			if ENV.has_key?(MAKEFILE_VAR)
				@vars[:variant] = "#{ENV[MAKEFILE_VAR]}"
			end

			if ENV.has_key?(BUILD_NUMBER)
				@vars[:build_num] = "#{ENV[BUILD_NUMBER]}"
			end

			if ENV.has_key?(VERSION_INI)
				@vars[:version_ini] = "#{ENV[VERSION_INI]}"
			end

			@vars[:vars_fil]     = "#{@vars[:usercontent]}/#{ENV['JOB_NAME']}.env"
			@vars[:makefile_fil] =
				@vars[:makefile_lst] = "#{@vars[:usercontent]}/#{@vars[:variant]}.make"
			@vars[:latest_fil]   = "#{@vars[:usercontent]}/#{@vars[:variant]}.latest"
			@vars[:latest_ver]   = ''
			@vars[:latest_sha]   = ''
			if File.exists?(@vars[:latest_fil])
				@vars[:latest_ver] = IO.readlines(@vars[:latest_fil])
				unless @vars[:latest_ver].is_a?(Array)
					@logger.error "Unable to parse latest version from #{@vars[:latest_fil]}"
					return -97
				end
				@vars[:latest_sha] = @vars[:latest_ver][1].chomp() if (@vars[:latest_ver].length > 1)
				@vars[:latest_ver] = @vars[:latest_ver][0].chomp()
			end
			0
		end

		# ---------------------------------------------------------------------------------------------------------------
		def saveEnvironment(ignored=[])
			@logger.info "Save environment to #{@vars[:vars_fil]}"
			vstr = [ "[global]" ]
			ENV.to_hash.sort.each{|k,v|
				vstr << %(#{k}="#{v}") unless ignored.include?(k)
			}

			IO.write(@vars[:vars_fil], vstr.join("\n"))
		end

		# ---------------------------------------------------------------------------------------------------------------
		def reportStatus(ignored)

			if @logger.level < ::Logging::LEVELS['warn']
				@logger.info '='*100
				@logger.info Dir.getwd()
				@logger.info '='*100

				@logger.info "Config:"
				@options.each{|k,v|
					unless ignored.include?(k)
						@logger.info sprintf("%25s: %s", "#{k.to_s}",  "#{v.to_s}")
					end
				}

				@logger.info '='*100

				@logger.info "Parameters:"
				@vars.sort.each{|k,v|
					unless ignored.include?(k)
						@logger.info sprintf("%25s: %s", "#{k.to_s}",  "#{v.to_s}")
					end
				}

				@logger.info '='*100
			end

			if @logger.level < ::Logging::LEVELS['info']
				@logger.debug '='*100
				@logger.debug "Environment:"
				ENV.sort.each{|k,v|
					unless ignored.include?(k)
						@logger.debug sprintf("%25s: %s", "#{k.to_s}",  "#{v.to_s}")
					end
				}

				@logger.debug '='*100
			end
		end

	end
end