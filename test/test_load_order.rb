# frozen_string_literal: true

require_relative 'test_helper'
require 'sin_fast_blank'

# ActiveSupport defines blank? on String itself, so whichever of the two is loaded last replaces the other. Left unchecked, a require
# order that drops the extension leaves every comparison in the suite running ActiveSupport against itself, which agrees on everything
# and reports a pass.
class TestLoadOrder < Minitest::Test
  def test_blank_is_the_extension_and_as_blank_is_activesupport
    blank_source_location = String.instance_method(:blank?).source_location

    refute_nil(AS_BLANK_SOURCE_LOCATION, 'as_blank? is not ActiveSupport: it has to be aliased before the extension loads')
    refute_equal(AS_BLANK_SOURCE_LOCATION, blank_source_location, 'blank? is ActiveSupport: the extension has to load after test_helper.rb')
  end
end
