# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'minitest/autorun'
require 'minitest/pride'
require 'active_support/core_ext/object/blank'

class String
  alias_method :as_blank?, :blank?
end
