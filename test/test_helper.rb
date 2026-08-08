# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'minitest/autorun'
require 'minitest/pride'
require 'active_support/core_ext/object/blank'
require_relative 'ractor_test_helper'
require_relative 'sweep_test_helper'

class String
  alias_method :as_blank?, :blank?
end

# Whatever blank? is at this point is ActiveSupport's, since the extension is required by the test files that load this one.
# Holding onto where it came from is what lets test_load_order.rb tell the two apart afterwards.
AS_BLANK_SOURCE_LOCATION = String.instance_method(:as_blank?).source_location
