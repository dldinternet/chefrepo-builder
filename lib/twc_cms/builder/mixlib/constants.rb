module TWC_CMS
	module Builder
		#noinspection RubyStringKeysInHashInspection
		LOGLEVELS = {
			'crit'     => :fatal,
			'critical' => :fatal,
			'err'      => :error,
			'error'    => :error,
			'warn'     => :warn,
			'warning'  => :warn,
			'info'     => :info,
			'debug'    => :debug,
		}

		MYNAME       = File.basename(__FILE__)
		MAKEFILE_URL = 'MAKEFILE_URL'
		MAKEFILE_REL = 'MAKEFILE_REL'
		MAKEFILE_VAR = 'MAKEFILE_VAR'
		MAKEFILE_LOC = 'MAKEFILE_LOC'
		WORKSPACE    = 'WORKSPACE'
		BUILD_TAG    = 'BUILD_TAG'
		PROJECT_NAME = 'PROJECT_NAME'
		BUILD_NUMBER = 'BUILD_NUMBER'
		JOB_NAME     = 'JOB_NAME'
		VERSION_INI  = 'VERSION_INI'


	end
end