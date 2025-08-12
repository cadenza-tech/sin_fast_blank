# frozen_string_literal: false

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'fast_blank'

class String
  alias_method :fast_blank?, :blank?
  alias_method :fast_blank_as?, :blank_as?

  undef_method :blank?
end

require 'sin_fast_blank'

class String
  alias_method :sin_blank?, :blank?
  alias_method :sin_ascii_blank?, :ascii_blank?

  undef_method :blank?
end

require 'active_support/core_ext/object/blank'

class String
  alias_method :as_blank?, :blank?

  undef_method :blank?
end

require_relative 'scratch_blank_methods'

class String
  include ScratchBlankMethods
end
