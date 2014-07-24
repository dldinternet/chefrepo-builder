module TWC_CMS
	module Builder
		file    = File.expand_path("#{File.dirname(__FILE__)}/../../../VERSION")
		lines   = File.readlines(file)
		version = lines[0]
		VERSION = version
		MAJOR, MINOR, TINY = VERSION.split('.')
		PATCH = TINY
	end
end
