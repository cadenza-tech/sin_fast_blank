# frozen_string_literal: false

require_relative 'test_helper'
require 'sin_fast_blank'

class TestBlank < Minitest::Test
  def test_equivalency
    test_strings = [
      '',
      ' ',
      '　',
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
    ]
    test_strings += (0..16 * 16 * 16 * 16).map { |i| i.chr('UTF-8') rescue nil }.compact # rubocop:disable Style/RescueModifier
    test_strings += (0..256).map { |i| i.chr('ASCII') rescue nil }.compact # rubocop:disable Style/RescueModifier

    test_strings.each do |string|
      assert_equal(string.as_blank?, string.blank?)
    end
  end

  def test_null_character
    refute_predicate("\u0000", :blank?)
  end
end
