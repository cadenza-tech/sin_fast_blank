# frozen_string_literal: false

require_relative 'test_helper'
require 'sin_fast_blank'

class TestBlank < Minitest::Test
  BASE_TEST_STRINGS = [
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
  ].freeze
  UTF8_CODEPOINT_MAX = 0xFFFF
  ASCII_CODEPOINT_MAX = 0xFF

  def test_equivalency
    test_strings = build_test_strings

    test_strings.each do |string|
      assert_equal(string.as_blank?, string.blank?)
    end
  end

  def test_null_character
    refute_predicate("\u0000", :blank?)
  end

  private

  def build_test_strings
    BASE_TEST_STRINGS + generate_utf8_chars + generate_ascii_chars
  end

  def generate_utf8_chars
    (0..UTF8_CODEPOINT_MAX).map { |i| safe_chr(i, 'UTF-8') }.compact
  end

  def generate_ascii_chars
    (0..ASCII_CODEPOINT_MAX).map { |i| safe_chr(i, 'ASCII') }.compact
  end

  def safe_chr(codepoint, encoding)
    codepoint.chr(encoding)
  rescue StandardError
    nil
  end
end
