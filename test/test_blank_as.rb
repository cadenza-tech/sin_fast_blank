# frozen_string_literal: false

$VERBOSE = nil

require_relative 'test_helper'
require 'sin_fast_blank'

class TestBlankAs < Minitest::Test
  def setup
    String.class_eval { undef_method(:blank?) if method_defined?(:blank?) }
    $LOADED_FEATURES.reject! { |f| f.include?('active_support/core_ext/object/blank.rb') }
    require 'active_support/core_ext/object/blank'
  end

  def test_equivalency
    ['', ' ', '　', "\r\n", "\r\n\v\f\r\s\t"].each do |s|
      assert_equal(s.blank?, s.blank_as?)
    end

    (16 * 16 * 16 * 16).times do |i|
      begin
        c = i.chr('UTF-8')
      rescue StandardError
        next
      end

      assert_equal(c.blank?, c.blank_as?)
    end

    256.times do |i|
      begin
        c = i.chr('ASCII')
      rescue StandardError
        next
      end

      assert_equal(c.blank?, c.blank_as?)
    end
  end

  def test_null_character
    refute_predicate("\u0000", :blank_as?)
  end
end
