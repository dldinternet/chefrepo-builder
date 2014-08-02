require './a/b'
include A::B

module A
  module B
    require 'awesome_print'
    %w(VERSION).each do |c|
      ap B.const_defined?(c)
    end
  end
end