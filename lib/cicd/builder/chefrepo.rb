require 'cicd/builder'
include CiCd::Builder

module CiCd
	module Builder
    _lib=File.dirname(__FILE__)
    $:.unshift(_lib) unless $:.include?(_lib)

    require 'cicd/builder/chefrepo/version'

    #noinspection ALL
    class ChefRepoBuilder < BuilderBase

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
        %w(VERSION RELEASE).each do |key|
          unless ENV.has_key?(key)
            ENV[key]="faked"
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
      def run()
        $stdout.write("ChefRepoBuilder v#{CiCd::Builder::ChefRepo::VERSION}\n")
        @default_options[:env_keys] = %w(
																			JENKINS_HOME
																			BUILD_NUMBER
                                      JOB_NAME
                                      WORKSPACE

																			PROJECT_NAME
                                      REPO_DIR
                                      REPO_PARTS

                                      VERSION
                                      RELEASE

																			AWS_S3_BUCKET
																		)
        @default_options[:gen] = '1.0.0'
        if 0 == super
          # noop
        end

        @vars[:return_code]
      end

      # ---------------------------------------------------------------------------------------------------------------
      def getVars()
        super
        @vars[:return_code]
      end

      # ---------------------------------------------------------------------------------------------------------------
      def prepareBuild()
        super
        local = {}
        %w(artifacts latest).each do |dir|
          local[dir] = "#{ENV['WORKSPACE']}/#{dir}"
          unless File.directory?(dir)
            Dir.mkdir(dir)
          end
        end
        unless ENV.has_key?('BUILD_STORE')
          @vars[:build_store] = File.join(ENV['WORKSPACE'],'latest')
        end
        @vars[:build_pkg]   = File.join(local['artifacts'],@vars[:build_rel]+'.tar.bz2')
        [ :build_chk, :build_mff, :build_mdf ].each do |file|
          @vars[file] = File.join(local['artifacts'],File.basename(@vars[file]))
        end
        ret = getLatest()
        @vars[:latest_pkg]= "#{@vars[:build_store]}/#{@vars[:build_rel]}.tar.bz2"
        @vars[:return_code] = ret
      end

      # ---------------------------------------------------------------------------------------------------------------
      def packageBuild()
        # excludes=%w(*.iml *.txt *.sh *.md .gitignore .editorconfig .jshintrc *.deprecated adminer doc)
        # excludes = excludes.map{ |e| "--exclude=#{@vars[:build_nam]}/#{e}" }.join(' ')
        raise "Not in WORKSPACE?" unless Dir.pwd == ENV['WORKSPACE']

        Dir.chdir ENV['REPO_DIR']
        if Dir.pwd == File.join(ENV['WORKSPACE'], ENV['REPO_DIR'])
          cmd = %(tar jcvf #{@vars[:build_pkg]} #{ENV['REPO_PARTS']} 2>&1)
          @logger.info cmd
          logger_info = %x(#{cmd})
          ret = $?.exitstatus
          @logger.info logger_info
          lines = logger_info.split("\n").map{ |line| line.split(/\s+/)[1] }
          IO.write @vars[:build_mff], lines.join("\n")
          FileUtils.rmtree(@vars[:build_dir])
          unless ret == 0
            FileUtils.rm_f(@vars[:build_mff])
          end
          ret
        else
          raise "Cannot change into '#{ENV['REPO_DIR']}' directory"
        end
      end

    end

  end
end