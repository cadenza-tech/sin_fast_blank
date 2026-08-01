# frozen_string_literal: true

class String
  # Explicitly undefine method before redefining to avoid Ruby warnings.
  undef_method(:blank?) if method_defined?(:blank?)
end

case RUBY_ENGINE
when 'jruby'
  require 'jruby'
  require 'sin_fast_blank/sin_fast_blank.jar'

  Java::sin_fast_blank::SinFastBlankLibrary.new.load(JRuby.runtime, false)
else
  # The extension-less require lets Ruby resolve the platform-specific shared library suffix (.bundle on macOS, .so elsewhere) via DLEXT.
  require 'sin_fast_blank/sin_fast_blank'
end

require 'sin_fast_blank/version'
