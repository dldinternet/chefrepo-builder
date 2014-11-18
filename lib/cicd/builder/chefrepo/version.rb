module CiCd
  # noinspection ALL
  module Builder
    module ChefRepo
      # %w(VERSION MAJOR MINOR TINY PATCH ).each do |c|
      #   remove_const c if const_defined?(c)
      # end

      VERSION  = '0.9.20'
      MAJOR, MINOR, TINY = VERSION.split('.')
      PATCH = TINY
    end
  end
end
