# frozen_string_literal: true

module SweepTestHelper
  UTF8_CODEPOINT_MAX = 0xFFFF
  ASCII_CODEPOINT_MAX = 0xFF
  SIMD_BOUNDARY_LENGTHS = [1, 7, 8, 15, 16, 17, 31, 32, 33, 43, 63, 64, 65, 127, 128, 129].freeze

  private

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

Minitest::Test.include(SweepTestHelper)
