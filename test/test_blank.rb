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
    [
      '',
      ' ',
      '	',
      "\r\n",
      "\t\n\v\f\r\s 	",
      "\t\n\v\f\r\s 	\t\n\v\f\r\s 	\t\n\v\f\r\s 	\t\n\v\f\r\s 	Lorem ipsum",
      '    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      '    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 🐈️', # rubocop:disable Layout/LineLength
      '    吾輩は猫である。名前はまだ無い。',
      '    吾輩は🐈️である。名前はまだ無い。',
      '🐈️',
      '    🐈️'
    ].each do |s|
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
