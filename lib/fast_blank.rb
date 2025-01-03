# frozen_string_literal: true

class ::String
  # Explicitly undefine method before redefining to avoid Ruby warnings.
  undef_method(:blank?) if method_defined?(:blank?)
end

case RUBY_ENGINE
when 'jruby'
  require 'fast_blank.jar'

  JRuby::Util.load_ext('com.headius.jruby.fast_blank.FastBlankLibrary')
else
  if RUBY_PLATFORM.include?('darwin')
    require 'fast_blank.bundle'
  else
    require 'fast_blank.so'
  end
end
