# frozen_string_literal: false

require_relative 'test_helper'
require 'sin_fast_blank'

class TestAsciiBlank < Minitest::Test
  def test_equivalency # rubocop:disable Metrics/MethodLength
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
      assert_equal(!!(s =~ /\A[[:space:]]*\z/), s.ascii_blank?) # rubocop:disable Style/DoubleNegation
    end

    (16 * 16 * 16 * 16).times do |i|
      begin
        c = i.chr('UTF-8')
      rescue StandardError
        next
      end

      assert_equal(c.strip.empty?, c.ascii_blank?)
    end

    256.times do |i|
      begin
        c = i.chr('ASCII')
      rescue StandardError
        next
      end

      assert_equal(c.strip.empty?, c.ascii_blank?)
    end
  end

  def test_null_character
    assert_predicate("\u0000", :ascii_blank?)
  end
end
