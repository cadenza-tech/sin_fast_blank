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
  NBSP = 0xA0.chr(Encoding::UTF_8)
  IDEOGRAPHIC_SPACE = 0x3000.chr(Encoding::UTF_8)

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

  # The chunk scan reports the first non-blank lane it finds, so the byte has to be found wherever it
  # sits: at the head of a chunk, inside one, and in the overlap the tail rescan reads twice.
  def test_non_blank_positions_at_simd_boundary_lengths
    SIMD_BOUNDARY_LENGTHS.each do |length|
      length.times do |position|
        string = spaces_with('x', length, position)

        refute_predicate(string, :blank?, "length #{length}, position #{position}")
      end
    end
  end

  def test_mixed_ascii_and_multibyte_equivalency
    SIMD_BOUNDARY_LENGTHS.each do |length|
      run = ' ' * length
      mixed_strings = [
        "#{NBSP}#{run}",
        "#{run}#{NBSP}",
        "#{NBSP}#{run}#{IDEOGRAPHIC_SPACE}#{run}",
        "#{run}#{IDEOGRAPHIC_SPACE}#{run}x",
        "#{NBSP}#{run}x#{run}"
      ]

      mixed_strings.each do |string|
        assert_equal(string.as_blank?, string.blank?, string.inspect)
      end
    end
  end

  # Where the vector scan stops it hands the position of the non-ASCII byte to the decoding loop, which
  # resumes there. Sweeping the character across every lane pins that handoff at each offset in a chunk.
  def test_multibyte_blank_positions_at_simd_boundary_lengths
    [NBSP, IDEOGRAPHIC_SPACE].each do |blank_char|
      SIMD_BOUNDARY_LENGTHS.each do |length|
        length.times do |position|
          string = spaces_with(blank_char, length, position)

          assert_equal(string.as_blank?, string.blank?, "length #{length}, position #{position}: #{string.inspect}")
        end
      end
    end
  end

  def test_blank_inside_ractor
    assert_equal([true, false, true], in_ractor { ['   '.blank?, 'a'.blank?, '　'.blank?] })
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

  # A run of ASCII spaces holding one other character, so a sweep can place that character in every lane.
  def spaces_with(char, length, position)
    "#{' ' * position}#{char}#{' ' * (length - position - 1)}"
  end
end
