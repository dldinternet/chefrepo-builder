module TWC_CMS
	module Builder

		# ---------------------------------------------------------------------------------------------------------------
		def getMakefile()

			unless ENV.has_key?(MAKEFILE_URL)
				@logger.error "#{MAKEFILE_URL}?"
				return 1
			end

			begin
				@vars[:makefile_url] = ENV[MAKEFILE_URL]
				uri = URI.parse(@vars[:makefile_url])
				http = Net::HTTP.new(uri.host, uri.port)
				@vars[:uri_host] = uri.host
				@vars[:uri_port] = uri.port
				@vars[:uri_path] = "#{uri.path}#{@vars[:uri_path]}"
				request = Net::HTTP::Get.new(@vars[:uri_path])
				response = http.request(request)

				if response.code == "200"
					@vars[:makefile_txt] = response.body
				else
					@logger.error "#{ENV[MAKEFILE_URL]}#{@vars[:uri_path]}} failed ... #{response.code}"
					@logger.info response.body
					return -96
				end
				@vars[:return_code] = 0
			rescue => e
				@logger.error e.to_s
				@vars[:return_code] = 3
			end
			@vars[:return_code]

		end

		# ---------------------------------------------------------------------------------------------------------------
		def parseMakefile(body=nil)
			body = @vars[:makefile_txt] if body.nil?
			arr = body.split(/\n/)
			meta = {}
			arr.each{|l|
				matches = l.match(/^; (Release|Branch|Commit|Date): (.*)/)
				if matches
					meta[matches[1].to_sym] = matches[2]
				end
			}
			use = arr.select{|l| not l.match(/^;/)}
			use.each{|l|
				l.gsub!(/\s+/,'')
				matches = l.match(/^([a-zA-Z0-9_\[\]]+)=(.*)$/)
				if matches
					if matches[1].match(/[\[\]]/)
						h = meta
						k = matches[1]
						v = matches[2].gsub(/['"]/,'')
						while k.match(/[\[\]]/)
							matches = k.match(/^(\w+)\[([^\[\]]+)\](.*)$/)
							if matches
								s = matches[1].to_sym
								unless h.has_key?(s)
									h[s] = {}
								end
								h = h[s]
								if (matches.size > 3) and (matches[3] != '')
									k = "#{matches[2]}#{matches[3]}"
								else
									k = matches[2]
								end
							else
								@logger.error "Cannot parse '#{k}' in line '#{l}'"
								return -98
							end
						end
						h[k.to_sym] = v
					else
						meta[matches[1].to_sym] = matches[2]
					end
				end
			}

			if  meta.has_key?(:Release)           and
					meta.has_key?(:Branch)            and
					meta.has_key?(:projects)          and
					meta[:projects].has_key?(:drupal) and
					meta[:projects][:drupal].has_key?(:version)
				# Ok the metadata has the minimum ...
				meta[:Commit]        = "UNKNOWN" unless meta.has_key?(:Commit)
				@vars[:makefile_ver] = meta[:Release]
				@vars[:makefile_bra] = meta[:Branch]
				@vars[:makefile_com] = meta[:Commit]
				@vars[:makefile_fil]  = "#{@vars[:usercontent]}/#{@vars[:variant]}.#{@vars[:makefile_ver]}.make"
				if ENV.has_key?(WORKSPACE)
					unless ENV.has_key?(PROJECT_NAME)
						raise 'PROJECT_NAME is required'
					end
					@vars[:build_bra] = meta[:Branch].gsub(%r([/|]),'.')
					@vars[:build_ver] = "#{meta[:projects][:drupal][:version]}.#{meta[:Release]}" # -#{@vars[:build_bra]}-#{@vars[:variant]}
					@vars[:build_vrb] = "#{@vars[:build_ver]}-#{@vars[:build_bra]}-#{@vars[:variant]}" #
					@vars[:build_nam] = "#{@vars[:project_name]}-#{@vars[:build_vrb]}"
					@vars[:build_rel] = "#{@vars[:build_nam]}-build-#{@vars[:build_num]}"
					@vars[:build_dir] = "#{ENV[WORKSPACE]}/#{@vars[:build_nam]}"
					@vars[:build_pkg] = "#{@vars[:build_dir]}.tar.gz"
					@vars[:build_chk] = "#{@vars[:build_dir]}.checksum"
				else
					raise 'WORKSPACE? Please teach me where the workspace is for this environment ...'
				end
				@vars[:makefile_met] = meta.dup
				meta.delete(:Date)
				#noinspection RubyArgCount
				@vars[:makefile_sha] = Digest::SHA256.hexdigest(meta.to_s)

				@vars[:return_code] = 0
			else
				@logger.error 'Bad makefile ... no Release metadata or projects[drupal][version]'
				@logger.error @vars[:makefile_txt]
				@vars[:return_code] = -99
			end

			@vars[:return_code]
		end

		# ---------------------------------------------------------------------------------------------------------------
		def saveMakefile()
			begin
				# [2013-12-30 Christo] Report status,environment, etc.
				reportStatus([:makefile_txt,:makefile_met])

				raise "ERROR: Checksum not read" unless @vars.has_key?(:latest_sha)
				raise "ERROR: Checksum not calculated" unless @vars.has_key?(:makefile_sha)
				change = false
				if @vars[:latest_sha] != @vars[:makefile_sha]
					change = true
					@logger.info "CHANGE: Checksum [#{@vars[:latest_sha]}] => [#{@vars[:makefile_sha]}]"
				end
				if @vars[:latest_ver] != @vars[:makefile_ver]
					change = true
					@logger.info "CHANGE: Release [#{@vars[:latest_ver]}] => [#{@vars[:makefile_ver]}]"
				end
				if not File.file?(@vars[:makefile_fil])
					change = true
					@logger.info "CHANGE: No #{@vars[:makefile_fil]}"
				end
				if not File.symlink?(@vars[:makefile_lst])
					change = true
					@logger.info "CHANGE: No #{@vars[:makefile_lst]}"
				end

				if change
					@logger.info "Save makefile to #{@vars[:makefile_fil]}"
					IO.write(@vars[:makefile_fil], @vars[:makefile_txt])
					if @vars[:makefile_lst] != @vars[:makefile_fil]
						@logger.info "Link #{@vars[:makefile_lst]} to #{@vars[:makefile_fil]}"
						begin
							File.unlink(@vars[:makefile_lst])
						rescue
							# noop
						end
						File.symlink(@vars[:makefile_fil], @vars[:makefile_lst])
					end
					@logger.info "Save release to #{@vars[:latest_fil]}"
					IO.write(@vars[:latest_fil], "#{@vars[:makefile_ver]}\n#{@vars[:makefile_sha]}")
					saveEnvironment(['LS_COLORS','AWS_ACCESS_KEY_ID','AWS_SECRET_ACCESS_KEY'])
					# NOTE the '.note'!
					@logger.note "CHANGE: #{ENV[JOB_NAME]} (#{@vars[:makefile_ver]}[#{@vars[:makefile_sha]}])"

					if ENV.has_key?(MAKEFILE_LOC)
						if ENV.has_key?(WORKSPACE)
							fil = %(#{ENV[WORKSPACE]}/#{File.basename(@vars[:makefile_fil])})
							unless fil == @vars[:makefile_fil]
								@logger.info "Save copy of #{@vars[:makefile_fil]} copy to #{fil}"
								IO.write(fil, @vars[:makefile_txt])
								lst = %(#{ENV[WORKSPACE]}/#{File.basename(@vars[:makefile_lst])})
								if lst != fil
									@logger.info "Link #{lst} to #{fil}"
									begin
										File.unlink(lst)
									rescue
										# noop
									end
									File.symlink(fil, lst)
								end
							end
						else
							@logger.warn "WORKSPACE?"
						end
					else
						@logger.warn "MAKEFILE_LOC?"
					end
				else
					@logger.info "Makefile #{@vars[:makefile_lst]} unchanged (#{@vars[:makefile_ver]} [#{@vars[:makefile_sha]}])"
					@logger.info "NO_CHANGE: #{ENV[JOB_NAME]} #{@vars[:makefile_ver]}"
				end
				@vars[:return_code] = 0
			rescue => e
				@logger.error "#{e.backtrace[0]}: #{e.class.name} #{e.message}"
				@vars[:return_code] = 2
			end
			@vars[:return_code]
		end

		# ---------------------------------------------------------------------------------------------------------------
		def readMakefile()
			begin
				@logger.debug @vars.ai
				@vars[:makefile_txt] = IO.read(@vars[:makefile_lst])
				@vars[:return_code] = 0
			rescue => e
				@logger.error "#{e.class.name} #{e.message}"
				@logger.error e.backtrace.ai
				@vars[:return_code] = -99
			end
			@vars[:return_code]
		end

		# ---------------------------------------------------------------------------------------------------------------
		def drushMakefile()
			if @vars.has_key?(:build_dir) and @vars.has_key?(:build_pkg)
				begin
					do_build = false
					if File.exists?(@vars[:build_chk])
						@vars[:build_sha] = IO.readlines(@vars[:build_chk])
						unless @vars[:build_sha].is_a?(Array)
							@logger.error "Unable to parse build checksum from #{@vars[:build_chk]}"
							return -97
						end
						@vars[:build_sha] = @vars[:build_sha][0].chomp()
					else
						@vars[:build_sha] = ''
						do_build = true
					end
					unless File.exists?(@vars[:build_pkg])
						do_build = true
					end
					if do_build
						@vars[:return_code] = cleanupBuild()
						return @vars[:return_code] unless @vars[:return_code] == 0
						drush = ENV.has_key?("DRUSH_CMD") ? File.expand_path(ENV['DRUSH_CMD']) : 'drush'
						cmd = %(#{drush} make #{@vars[:makefile_fil]} #{@vars[:build_dir]})
						@logger.info cmd
						logger_info = %x(#{cmd})
						@logger.info logger_info
						@vars[:build_dte] = DateTime.now.strftime("%F %T%:z")
						@vars[:return_code] = $?.exitstatus
						if @vars[:return_code] == 0
							createINIFile()
							@vars[:return_code] = packageBuild()
							if 0 == @vars[:return_code]
								check_sha = @vars[:build_sha]
								@vars[:build_sha] = Digest::SHA256.file(@vars[:build_pkg]).hexdigest()
								IO.write(@vars[:build_chk], @vars[:build_sha])
							end
							# [2013-12-30 Christo] Report status,environment, etc.
							reportStatus([:makefile_txt,:makefile_met])
							if 0 == @vars[:return_code]
								# NOTE the '.note'!
								@logger.note  "CHANGE:  #{ENV[JOB_NAME]} #{ENV[BUILD_NUMBER]} #{@vars[:build_nam]} (#{@vars[:makefile_fil]}) [#{check_sha}] => [#{@vars[:build_sha]}]"
							else
								@logger.error "FAILURE: #{ENV[JOB_NAME]} #{ENV[BUILD_NUMBER]} #{@vars[:build_pkg]} #{@vars[:return_code]}"
							end
						else
							@logger.error "FAILURE: #{ENV[JOB_NAME]} #{ENV[BUILD_NUMBER]} #{@vars[:build_nam]} #{@vars[:return_code]}"
							cleanupBuild()
						end
					else
						# [2013-12-30 Christo] Report status,environment, etc.
						reportStatus([:makefile_txt,:makefile_met])

						# No need to build again :)
						@logger.info "NO_CHANGE: #{ENV[JOB_NAME]} #{ENV[BUILD_NUMBER]} #{@vars[:build_nam]} #{@vars[:build_pkg]} #{@vars[:build_chk]} [#{@vars[:build_sha]}]"
						@vars[:return_code] = 0
						return 1
					end
				rescue => e
					@logger.error "#{e.class.name} #{e.message}"
					@vars[:return_code] = -99
				end
			else
				@logger.error ":build_dir or :build_pkg is unknown"
				@vars[:return_code] = 2
			end
			@vars[:return_code]
		end

	end
end