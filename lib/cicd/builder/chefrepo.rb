require 'cicd/builder'
include CiCd::Builder

module CiCd
	module Builder
    _lib=File.dirname(__FILE__)
    $:.unshift(_lib) unless $:.include?(_lib)

    require 'cicd/builder/chefrepo/version'

    module ChefRepo
      class Runner < BuilderBase

        def initialize()
          super
          @default_options[:builder] = VERSION
        end

        # ---------------------------------------------------------------------------------------------------------------
        def getBuilderVersion
          {
              version:  VERSION,
              major:    MAJOR,
              minor:    MINOR,
              patch:    PATCH,
          }
        end

        # ---------------------------------------------------------------------------------------------------------------
        def checkEnvironment()
          # We fake some of the keys that the will need later ...
          faked = {}
          %w(VERSION RELEASE VARIANT).each do |key|
            unless ENV.has_key?(key)
              ENV[key]='faked'
              faked[key] = true
            end
          end
          ret = super
          faked.each do |k,v|
            ENV.delete k
          end
          ret
        end

        # ---------------------------------------------------------------------------------------------------------------
        def setup()
          $stdout.write("ChefRepoBuilder v#{CiCd::Builder::ChefRepo::VERSION}\n")
          @default_options[:env_keys] << %w(
																			JENKINS_HOME
																			BUILD_NUMBER
                                      JOB_NAME
                                      WORKSPACE

																			PROJECT_NAME
                                      REPO_DIR

                                      VERSION
                                      RELEASE
                                      VARIANT
                                      BRANCH
																		)
          # @default_options[:gen] = '1.0.0'
          super
        end

        # # ---------------------------------------------------------------------------------------------------------------
        # def getVars()
        #   super
        #   @vars[:return_code]
        # end

        # ---------------------------------------------------------------------------------------------------------------
        def prepareBuild()
          ret = super
          if ret == 0
            unless ENV.has_key?('BUILD_STORE')
              @vars[:build_store] = File.join(ENV['WORKSPACE'],'latest')
            end
            @vars[:build_ext] = 'tar.bz2'
            @vars[:build_pkg] = File.join(@vars[:local_dirs]['artifacts'],@vars[:build_nmn]+".#{@vars[:build_ext]}")
            [ :build_chk, :build_mff, :build_mdf ].each do |file|
              @vars[file] = File.join(@vars[:local_dirs]['artifacts'],File.basename(@vars[file]))
            end
            @vars[:latest_pkg]= "#{@vars[:build_store]}/#{@vars[:build_nmn]}.#{@vars[:build_ext]}"

            artifacts     = []
            scripts       = File.join(ENV['WORKSPACE'], ENV['REPO_DIR'], 'scripts', '')
            scripts_glob  = File.join(scripts,'**','**')
            Dir.glob(scripts_glob).each do |script|
              if File.file?(script)
                addArtifact(artifacts, script, scripts)
              end
            end
            @vars[:artifacts] = artifacts
            ret = getLatest()
          end
          @vars[:return_code] = ret
        end

        # ---------------------------------------------------------------------------------------------------------------
        def packageBuild()
          @logger.step __method__.to_s
          # excludes=%w(*.iml *.txt *.sh *.md .gitignore .editorconfig .jshintrc *.deprecated adminer doc)
          # excludes = excludes.map{ |e| "--exclude=#{@vars[:build_nam]}/#{e}" }.join(' ')

          if isSameDirectory(Dir.pwd, ENV['WORKSPACE'])
            Dir.chdir ENV['REPO_DIR']
            if isSameDirectory(Dir.pwd, File.join(ENV['WORKSPACE'], ENV['REPO_DIR']))
              if ENV.has_key?('REPO_PARTS') and not ENV['REPO_PARTS'].empty?
                cmd = %(tar jcvf #{@vars[:build_pkg]} #{ENV['REPO_PARTS']} 2>&1)
                @logger.info cmd
                logger_info = %x(#{cmd})
                @vars[:return_code] = $?.exitstatus
                if @vars[:return_code] == 0
                  @logger.debug logger_info
                  lines = logger_info.split("\n").map { |line| line.split(/\s+/)[1] }
                  begin
                    unless IO.write(@vars[:build_mff], lines.join("\n")) > 0
                      @logger.error "Nothing was written to manifest '#{@vars[:build_mff]}'"
                      @vars[:return_code] = Errors::MANIFEST_EMPTY
                    end
                  rescue Exception => e
                    @logger.error "Failed to write manifest: #{e.class.name} #{e.message} ('#{@vars[:build_mff]}')"
                    @vars[:return_code] = Errors::MANIFEST_WRITE
                  end
                  FileUtils.rmtree(@vars[:build_dir])
                else
                  @logger.error "Failed to package '#{@vars[:build_pkg]}': #{logger_info}"
                end
                unless @vars[:return_code] == 0
                  @logger.warn "Remove manifest '#{@vars[:build_mff]}' due to error"
                  FileUtils.rm_f(@vars[:build_mff])
                end
              end
            else
              @logger.error "Cannot change into '#{ENV['REPO_DIR']}' directory"
              @vars[:return_code] = Errors::REPO_DIR
            end
          else
            @logger.error "Not in WORKSPACE? '#{pwd}' does not match WORKSPACE='#{workspace}'"
            @vars[:return_code] = Errors::WORKSPACE_DIR
          end

          @vars[:return_code]
        end
      end
    end

  end
end
