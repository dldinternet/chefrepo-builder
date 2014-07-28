module CiCd
  # noinspection ALL
  module Builder
      %w(VERSION MAJOR MINOR TINY PATCH ).each do |c|
        self.remove_const c if self.const_defined?(c)
      end

      VERSION  = '0.1.0'
      MAJOR, MINOR, TINY = VERSION.split('.')
      PATCH = TINY
  end
end
