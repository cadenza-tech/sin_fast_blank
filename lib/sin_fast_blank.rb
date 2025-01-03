# frozen_string_literal: true

class ::String
  # Explicitly undefine method before redefining to avoid Ruby warnings.
  undef_method(:blank?) if method_defined?(:blank?)
end

case RUBY_ENGINE
when 'jruby'
  require 'sin_fast_blank/sin_fast_blank.jar'

  JRuby::Util.load_ext('sin_fast_blank.SinFastBlankLibrary')
else
  if RUBY_PLATFORM.include?('darwin')
    require 'sin_fast_blank.bundle'
  else
    require 'sin_fast_blank.so'
  end
end

require 'sin_fast_blank/version'
