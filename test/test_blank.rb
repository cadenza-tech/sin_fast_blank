# frozen_string_literal: false

$VERBOSE = nil

require_relative 'test_helper'

class ::String
  def scratch_blank?
    !!(self =~ /\A[[:space:]]*\z/)
  end
end

class TestBlank < Minitest::Test
  def setup
    String.class_eval { undef_method(:blank?) if method_defined?(:blank?) }
    $LOADED_FEATURES.reject! { |f| f.include?('sin_fast_blank') }
    require 'sin_fast_blank'
  end

  def test_equivalency
    ['', ' ', "\r\n", "\r\n\v\f\r\s\t"].each do |s|
      assert_equal(s.scratch_blank?, s.blank?)
    end
  end

  def test_empty
    (16 * 16 * 16 * 16).times do |i|
      begin
        c = i.chr('UTF-8')
      rescue StandardError
        next
      end

      assert_equal(c.strip.empty?, c.blank?)
    end

    256.times do |i|
      begin
        c = i.chr('ASCII')
      rescue StandardError
        next
      end

      assert_equal(c.strip.empty?, c.blank?)
    end
  end

  def test_null_character
    assert_predicate("\u0000", :blank?)
  end
end
