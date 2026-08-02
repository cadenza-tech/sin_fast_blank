# frozen_string_literal: false

require_relative 'test_helper'
require 'sin_fast_blank'

class TestBlankEncoding < Minitest::Test
  # JRuby 9.1 rejects GB18030 four-byte sequences, so compare only what the engine accepts.
  ASCII_COMPATIBLE_STRINGS = [
    '　'.encode('Shift_JIS'),
    "\t\r\n ".encode('Shift_JIS'),
    ' 　 '.encode('Shift_JIS'),
    'テスト'.encode('Shift_JIS'), # trail bytes in the 0x40-0x7E range
    '  テ'.encode('Shift_JIS'),
    '　'.encode('EUC-JP'),
    " 　\t".encode('EUC-JP'),
    'あ い'.encode('EUC-JP'),
    '　'.encode('Windows-31J'),
    " \t".encode('Windows-31J'),
    ' '.encode('ISO-8859-1'),
    '   '.encode('ISO-8859-1'),
    'a '.encode('ISO-8859-1'),
    " \t".encode('US-ASCII'),
    # GB18030 4-byte characters decode to codepoints above INT_MAX; they must reach the blank
    # switch as they are, not narrowed into something the ctype lookup would accept.
    [0x85].pack('U').encode('GB18030'),
    " #{[0x20000].pack('U')}".encode('GB18030'),
    ' 　 '.encode('GB18030')
  ].select(&:valid_encoding?).freeze
  # Unicode encodings that are not named UTF-8. The byte sweeps below stop at two-byte characters,
  # leaving every blank from U+1680 up untested, so these pin the encoding detection that picks the table.
  UNICODE_REPLICA_ENCODINGS = %w[UTF8-MAC UTF8-DoCoMo UTF8-KDDI UTF8-SoftBank CESU-8].select { |name| Encoding.name_list.include?(name) }.freeze
  UNICODE_REPLICA_SAMPLES = ["\u3000", "\u2028", " \u205F", "a\u00A0"].freeze
  UNICODE_REPLICA_STRINGS = UNICODE_REPLICA_ENCODINGS.flat_map do |name|
    UNICODE_REPLICA_SAMPLES.map { |string| string.dup.force_encoding(name) }
  end.freeze
  UTF16_BLANK_STRING = "　 \t".encode('UTF-16LE').freeze
  UTF16_NON_BLANK_STRING = 'a b'.encode('UTF-16LE').freeze
  UTF16_ASCII_BLANK_STRING = " \t".encode('UTF-16LE').freeze
  # A lead surrogate with no trail. The byte count stays even, which TruffleRuby's force_encoding insists on.
  UTF16_INVALID_STRING = "\x00\xD8".force_encoding('UTF-16LE').freeze
  # ActiveSupport matches [[:space:]] against the encoding's own ctype table, the same table
  # rb_enc_isspace and jcodings expose. TruffleRuby's regexp engine uses a different one and reports
  # 0x85 and 0xA0 as blank. Tolerating those two keeps the sweeps running there; skipping the sweeps
  # would leave TruffleRuby with no equivalency coverage at all.
  DIVERGENT_SINGLE_BYTES = ((RUBY_ENGINE == 'truffleruby') ? [0x85, 0xa0] : []).freeze
  # Every codepoint ActiveSupport can call blank, plus non-blank ones whose low byte is a blank byte
  # (what a narrowed codepoint decays into). Walking these covers widths the byte sweeps cannot reach.
  BLANK_CODEPOINTS = [0x9, 0xa, 0xb, 0xc, 0xd, 0x20, 0x85, 0xa0, 0x1680, *(0x2000..0x200a), 0x2028, 0x2029, 0x202f, 0x205f, 0x3000].freeze
  NARROWING_CODEPOINTS = [0x109, 0x120, 0x185, 0x1a0, 0x40d, 0x1009, 0x300d, 0x3020, 0x3085, 0x30a0].freeze
  DECIDING_CODEPOINTS = (BLANK_CODEPOINTS + NARROWING_CODEPOINTS).freeze
  # Dummy encodings are left out: ActiveSupport cannot build a regexp for them at all, so there is nothing to compare against.
  ENCODINGS = Encoding.list.reject(&:dummy?).freeze
  ASCII_COMPATIBLE_ENCODINGS = ENCODINGS.select(&:ascii_compatible?).freeze

  # Both lists shrink with the engine; empty they would assert nothing and still pass.
  def test_ascii_compatible_encodings_equivalency
    refute_empty(ASCII_COMPATIBLE_STRINGS)

    ASCII_COMPATIBLE_STRINGS.each do |string|
      assert_equal(string.as_blank?, string.blank?, describe(string))
    end
  end

  def test_unicode_replica_encodings_equivalency
    refute_empty(UNICODE_REPLICA_STRINGS)

    UNICODE_REPLICA_STRINGS.each do |string|
      assert_equal(string.as_blank?, string.blank?, describe(string))
    end
  end

  # Sweeping every encoding, not a chosen few, is what catches a ctype table that answers something
  # other than "is this blank?" (Emacs-Mule does). Mismatches are collected rather than asserted per
  # byte so a divergence is reported in full instead of stopping at its first byte.
  def test_every_encoding_single_byte_equivalency
    mismatches = collect_single_byte_mismatches

    assert_empty(mismatches, mismatch_message(mismatches))
  end

  def test_ascii_compatible_encodings_two_byte_equivalency
    mismatches = collect_two_byte_mismatches

    assert_empty(mismatches, mismatch_message(mismatches))
  end

  def test_every_encoding_deciding_codepoint_equivalency
    mismatches = collect_codepoint_mismatches

    assert_empty(mismatches, mismatch_message(mismatches))
  end

  # The tolerance the sweeps grant has to stay earned. Which encodings disagree is a TruffleRuby
  # detail, so this only asks that each tolerated byte still disagrees somewhere; should one stop,
  # the list can shrink. The sweeps themselves catch the list being too short.
  def test_divergent_single_bytes_still_disagree
    skip 'no divergence to pin on this engine' if DIVERGENT_SINGLE_BYTES.empty?

    disagreeing = DIVERGENT_SINGLE_BYTES.select { |byte| ENCODINGS.any? { |encoding| disagrees?(byte, encoding) } }

    assert_equal(DIVERGENT_SINGLE_BYTES, disagreeing)
  end

  def test_utf16_blank_detection
    assert_predicate(UTF16_BLANK_STRING, :blank?)
  end

  def test_utf16_non_blank_detection
    refute_predicate(UTF16_NON_BLANK_STRING, :blank?)
  end

  def test_invalid_byte_sequences_raise_argument_error
    [
      "\xFF", " \xFF", "\xE3\x80", " \xE3\x80",
      "\x82".force_encoding('Shift_JIS'), " \xA1".force_encoding('EUC-JP'), UTF16_INVALID_STRING
    ].each do |string|
      assert_raises(ArgumentError, describe(string)) { string.blank? }
    end
  end

  # ActiveSupport raises ArgumentError here because its regexp validates the whole string,
  # while SinFastBlank keeps fast_blank's early exit: the leading non-blank ASCII character
  # decides the result before the invalid byte is ever examined.
  def test_invalid_byte_sequence_after_non_blank_ascii_returns_false
    refute_predicate("a\xFF", :blank?)
  end

  # Ruby's Big5 transcoders emit byte sequences their own scanner rejects while the code range still
  # reads valid. ActiveSupport reads that code range and never rescans, so it answers rather than
  # raising, and blank? has to do the same to stay a drop-in replacement.
  def test_transcoder_only_byte_sequence_matches_activesupport
    assert_equal(transcoder_only_string.as_blank?, transcoder_only_string.blank?, describe(transcoder_only_string))
    refute_predicate(transcoder_only_string, :blank?)
  end

  # Reaches ascii_blank?'s decoding loop, which an ASCII-compatible encoding never needs.
  # The blank string is refuted because an ideographic space is blank without being an ASCII blank.
  def test_utf16_ascii_blank_detection
    assert_predicate(UTF16_ASCII_BLANK_STRING, :ascii_blank?)
    refute_predicate(UTF16_BLANK_STRING, :ascii_blank?)
  end

  # Undecodable bytes are not ASCII blanks whether or not they form a character, so ascii_blank?
  # answers instead of raising, wherever they sit.
  def test_invalid_byte_sequences_return_false_for_ascii_blank
    ["\xFF", " \xFF", "a\xFF", "\x82".force_encoding('Shift_JIS'), transcoder_only_string, UTF16_INVALID_STRING].each do |string|
      refute_predicate(string, :ascii_blank?, describe(string))
    end
  end

  private

  # Ruby's Big5-HKSCS transcoder emits 88 59 for this character, a sequence the encoding's own scanner
  # rejects, and leaves the code range reading valid. Built fresh each call and never frozen: up to
  # Ruby 3.1 String#freeze recomputes the code range, which turns it into a plainly broken string.
  def transcoder_only_string
    'À'.encode('Big5-HKSCS')
  end

  def collect_single_byte_mismatches
    mismatches = []

    ENCODINGS.each do |encoding|
      (0x00..0xFF).each do |byte|
        string = tagged(byte.chr, encoding)

        mismatches << describe(string) if string && mismatch?(string)
      end
    end

    mismatches
  end

  def collect_two_byte_mismatches
    mismatches = []

    ASCII_COMPATIBLE_ENCODINGS.each do |encoding|
      (0x80..0xFF).each do |lead|
        (0x00..0xFF).each do |trail|
          string = tagged([lead, trail].pack('C*'), encoding)

          mismatches << describe(string) if string && mismatch?(string)
        end
      end
    end

    mismatches
  end

  def collect_codepoint_mismatches
    mismatches = []

    ENCODINGS.each do |encoding|
      DECIDING_CODEPOINTS.each do |codepoint|
        string = encoded(codepoint, encoding)

        mismatches << describe(string) if string && mismatch?(string)
      end
    end

    mismatches
  end

  # nil when the encoding has no character for the codepoint, or no converter at all.
  def encoded(codepoint, encoding)
    string = [codepoint].pack('U').encode(encoding)
    string if string.valid_encoding?
  rescue Encoding::UndefinedConversionError, Encoding::ConverterNotFoundError
    nil
  end

  # nil when there is nothing to compare. TruffleRuby's force_encoding rejects a byte count the
  # encoding cannot hold (UTF-16 needs an even one) where CRuby just tags the bytes and moves on.
  def tagged(bytes, encoding)
    string = bytes.force_encoding(encoding)
    string if string.valid_encoding?
  rescue ArgumentError
    nil
  end

  def mismatch?(string)
    return false if divergent?(string)

    string.as_blank? != string.blank?
  end

  def disagrees?(byte, encoding)
    string = tagged(byte.chr, encoding)

    !string.nil? && string.as_blank? != string.blank?
  end

  # Only where the byte stands as a character of its own, so multi-byte encodings keep full coverage.
  def divergent?(string)
    return false if DIVERGENT_SINGLE_BYTES.empty?

    string.bytesize == string.length && string.bytes.any? { |byte| DIVERGENT_SINGLE_BYTES.include?(byte) }
  end

  # Not String#inspect: TruffleRuby raises on GB18030 four-byte sequences while building it.
  def describe(string)
    "#{string.encoding.name} #{string.bytes.map { |byte| format('%02X', byte) }.join}"
  end

  def mismatch_message(mismatches)
    "#{mismatches.size} sequences disagree with ActiveSupport: #{mismatches.first(20).join(', ')}"
  end
end
