# frozen_string_literal: false

require_relative 'test_helper'
require 'sin_fast_blank'

class TestAsciiBlank < Minitest::Test
  TEST_STRINGS = [
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
  ].freeze
  UTF8_CODEPOINT_MAX = 0xFFFF
  ASCII_CODEPOINT_MAX = 0xFF
  SIMD_BOUNDARY_LENGTHS = [1, 7, 8, 15, 16, 17, 31, 32, 33, 43, 63, 64, 65, 127, 128, 129].freeze

  def test_equivalency
    test_strings_equivalency
    test_utf8_chars_equivalency
    test_ascii_chars_equivalency
  end

  def test_null_character
    assert_predicate("\u0000", :ascii_blank?)
  end

  def test_ascii_blank_strings_at_simd_boundary_lengths
    SIMD_BOUNDARY_LENGTHS.each do |length|
      assert_predicate(' ' * length, :ascii_blank?, "length #{length}")
    end
  end

  def test_null_characters_at_simd_boundary_lengths
    SIMD_BOUNDARY_LENGTHS.each do |length|
      assert_predicate("#{0.chr}#{' ' * (length - 1)}", :ascii_blank?, "length #{length}")
    end
  end

  def test_non_blank_edges_at_simd_boundary_lengths
    SIMD_BOUNDARY_LENGTHS.each do |length|
      ["x#{' ' * (length - 1)}", "#{' ' * (length - 1)}x"].each do |string|
        refute_predicate(string, :ascii_blank?, "length #{length}: #{string.inspect}")
      end
    end
  end

  private

  def test_strings_equivalency
    TEST_STRINGS.each do |s|
      expected = ascii_space_only?(s)

      assert_equal(expected, s.ascii_blank?)
    end
  end

  def test_utf8_chars_equivalency
    UTF8_CODEPOINT_MAX.times do |i|
      char = safe_chr(i, 'UTF-8')
      next unless char

      assert_equal(char.strip.empty?, char.ascii_blank?)
    end
  end

  def test_ascii_chars_equivalency
    ASCII_CODEPOINT_MAX.times do |i|
      char = safe_chr(i, 'ASCII')
      next unless char

      assert_equal(char.strip.empty?, char.ascii_blank?)
    end
  end

  def ascii_space_only?(str)
    !!(str =~ /\A[[:space:]]*\z/)
  end

  def safe_chr(codepoint, encoding)
    codepoint.chr(encoding)
  rescue StandardError
    nil
  end
end
