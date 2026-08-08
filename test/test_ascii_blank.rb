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

  def test_equivalency
    assert_test_strings_equivalency
    assert_utf8_chars_equivalency
    assert_ascii_chars_equivalency
  end

  def test_null_character
    assert_predicate("\u0000", :ascii_blank?)
  end

  def test_ascii_blank_strings_at_simd_boundary_lengths
    SIMD_BOUNDARY_LENGTHS.each do |length|
      assert_predicate(' ' * length, :ascii_blank?, "length #{length}")
    end
  end

  # NUL is matched by a comparison of its own, separate from the whitespace range, so it has to be
  # recognized in every lane rather than only at the head of the string.
  def test_null_character_positions_at_simd_boundary_lengths
    SIMD_BOUNDARY_LENGTHS.each do |length|
      length.times do |position|
        string = spaces_with(0.chr, length, position)

        assert_predicate(string, :ascii_blank?, "length #{length}, position #{position}")
      end
    end
  end

  # The chunk scan reports the first non-blank lane it finds, so the byte has to be found wherever it
  # sits: at the head of a chunk, inside one, and in the overlap the tail rescan reads twice.
  def test_non_blank_positions_at_simd_boundary_lengths
    SIMD_BOUNDARY_LENGTHS.each do |length|
      length.times do |position|
        string = spaces_with('x', length, position)

        refute_predicate(string, :ascii_blank?, "length #{length}, position #{position}")
      end
    end
  end

  def test_ascii_blank_inside_ractor
    assert_equal([true, false], in_ractor { [' '.ascii_blank?, 'a'.ascii_blank?] })
  end

  private

  def assert_test_strings_equivalency
    TEST_STRINGS.each do |s|
      expected = ascii_space_only?(s)

      assert_equal(expected, s.ascii_blank?)
    end
  end

  def assert_utf8_chars_equivalency
    UTF8_CODEPOINT_MAX.times do |i|
      char = safe_chr(i, 'UTF-8')
      next unless char

      assert_equal(char.strip.empty?, char.ascii_blank?)
    end
  end

  def assert_ascii_chars_equivalency
    ASCII_CODEPOINT_MAX.times do |i|
      char = safe_chr(i, 'ASCII')
      next unless char

      assert_equal(char.strip.empty?, char.ascii_blank?)
    end
  end

  def ascii_space_only?(str)
    !!(str =~ /\A[[:space:]]*\z/)
  end
end
