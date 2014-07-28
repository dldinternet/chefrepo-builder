module CiCd
  # noinspection ALL
  module Builder
      # noinspection RubyInstanceVariableNamingConvention
      #file    = File.expand_path("#{File.dirname(__FILE__)}/../../../VERSION")
      #lines   = File.readlines(file)
      #version = lines[0]
      remove_const 'VERSION'
      VERSION  = '0.1.0'
      remove_const 'MAJOR'
      remove_const 'MINOR'
      remove_const 'TINY'
      remove_const 'PATCH'
      MAJOR, MINOR, TINY = VERSION.split('.')
      PATCH = TINY
  end
end
