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
  SIMD_BOUNDARY_LENGTHS = [1, 7, 8, 15, 16, 17, 31, 32, 33, 43, 63, 64, 65, 127, 128, 129].freeze

  def test_equivalency
    test_strings = build_test_strings

    test_strings.each do |string|
      assert_equal(string.as_blank?, string.blank?)
    end
  end

  def test_null_character
    refute_predicate("\u0000", :blank?)
  end

  def test_blank_strings_at_simd_boundary_lengths
    SIMD_BOUNDARY_LENGTHS.each do |length|
      assert_predicate(' ' * length, :blank?, "length #{length}")
    end
  end

  def test_non_blank_edges_at_simd_boundary_lengths
    SIMD_BOUNDARY_LENGTHS.each do |length|
      ["x#{' ' * (length - 1)}", "#{' ' * (length - 1)}x"].each do |string|
        refute_predicate(string, :blank?, "length #{length}: #{string.inspect}")
      end
    end
  end

  def test_mixed_ascii_and_multibyte_equivalency
    nbsp = 0xA0.chr(Encoding::UTF_8)
    ideographic_space = 0x3000.chr(Encoding::UTF_8)

    SIMD_BOUNDARY_LENGTHS.each do |length|
      run = ' ' * length
      mixed_strings = [
        "#{nbsp}#{run}",
        "#{run}#{nbsp}",
        "#{nbsp}#{run}#{ideographic_space}#{run}",
        "#{run}#{ideographic_space}#{run}x",
        "#{nbsp}#{run}x#{run}"
      ]

      mixed_strings.each do |string|
        assert_equal(string.as_blank?, string.blank?, string.inspect)
      end
    end
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
