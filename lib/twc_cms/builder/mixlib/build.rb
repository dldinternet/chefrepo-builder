module TWC_CMS
	module Builder

		# ---------------------------------------------------------------------------------------------------------------
		def cleanupBuild()
			if File.exists?(@vars[:build_pkg])
				begin
					FileUtils.rm_f(@vars[:build_pkg])
				rescue => e
					@logger.error e.to_s
					#raise e
					return -96
				end
			end
			if Dir.exists?(@vars[:build_dir])
				begin
					FileUtils.rm_r(@vars[:build_dir])
				rescue => e
					@logger.error e.to_s
					#raise e
					return -95
				end
			end
			0
		end

		# ---------------------------------------------------------------------------------------------------------------
		def createINIFile()
			IO.write("#{@vars[:build_dir]}/#{@vars[:version_ini]}",
			         <<-EOVI
; Gen: #{@options[:gen]}
; Project name
TWC_PROJECT = "#{@vars[:project_name]}"
; Branch name this build was taken from
TWC_BRANCH = "#{@vars[:build_bra]}"
; Build type
TWC_TYPE = #{@vars[:variant]}
; Build number generated by CI build system
TWC_BUILD = #{@vars[:build_num]}
; Version number issued by Packaging Server
TWC_VERSION = #{@vars[:build_ver]}
; Last Commit ID available when this build was made
TWC_GIT_HEAD = #{@vars[:makefile_com]}
; Date of build
TWC_BUILD_DATE = #{@vars[:build_dte]}
; Builder version
TWC_BUILDER = #{TWC_CMS::Builder::VERSION}
			EOVI
			)
		end

		# ---------------------------------------------------------------------------------------------------------------
		def packageBuild()
			excludes=%w(*.iml *.txt *.sh *.md .gitignore .editorconfig .jshintrc *.deprecated adminer doc)
			excludes = excludes.map{ |e| "--exclude=#{@vars[:build_nam]}/#{e}" }.join(' ')
			cmd = %(cd #{ENV[WORKSPACE]}; tar zcvf #{@vars[:build_pkg]} #{excludes} #{@vars[:build_nam]} 1>#{@vars[:build_pkg]}.manifest)
			@logger.info cmd
			logger_info = %x(#{cmd})
			ret = $?.exitstatus
			@logger.info logger_info
			FileUtils.rmtree(@vars[:build_dir])
			ret
		end

	end
end