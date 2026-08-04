package sin_fast_blank;

import org.jcodings.Encoding;
import org.jruby.Ruby;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;
import org.jruby.util.ByteList;
import org.jruby.util.StringSupport;

public class SinFastBlankLibrary implements Library {
    private static final int MAX_CTYPE_CODEPOINT = 0xFF;

    @Override
    public void load(Ruby runtime, boolean wrap) {
        runtime.getString().defineAnnotatedMethods(SinFastBlankLibrary.class);
    }

    @JRubyMethod(name = "blank?")
    public static IRubyObject blank_p(ThreadContext context, IRubyObject self) {
        RubyString str = (RubyString) self;
        ByteList byteList = str.getByteList();
        if (byteList.realSize() == 0) {
            return context.tru;
        }

        byte[] bytes = byteList.unsafeBytes();
        int s = byteList.begin();
        int e = s + byteList.realSize();
        Encoding enc = str.getEncoding();

        if (enc.isAsciiCompatible()) {
            for (int i = s; i < e; i++) {
                byte c = bytes[i];
                if (c < 0) {
                    return blankMixed(context, str, bytes, i, e, enc);
                }
                if (!isAsciiBlank(c)) {
                    return context.fals;
                }
            }
            return context.tru;
        }

        return blankUnicodeSlow(context, str, bytes, s, e, enc);
    }

    private static boolean isAsciiBlank(byte c) {
        return (c >= 0x09 && c <= 0x0d) || c == 0x20;
    }

    private static boolean isUnicodeBlank(int codepoint) {
        switch (codepoint) {
            case 0x9:
            case 0xa:
            case 0xb:
            case 0xc:
            case 0xd:
            case 0x20:
            case 0x85:
            case 0xa0:
            case 0x1680:
            case 0x2000:
            case 0x2001:
            case 0x2002:
            case 0x2003:
            case 0x2004:
            case 0x2005:
            case 0x2006:
            case 0x2007:
            case 0x2008:
            case 0x2009:
            case 0x200a:
            case 0x2028:
            case 0x2029:
            case 0x202f:
            case 0x205f:
            case 0x3000:
                return true;
            default:
                return false;
        }
    }

    /*
     * ActiveSupport's blank regexp matches [[:space:]] with the ctype table of the string's own
     * encoding, which differs from the Unicode table for some encodings (e.g. 0x85 is blank in
     * UTF-8 but not in ISO-8859-1 or ASCII-8BIT). isSpace() reads that same table.
     *
     * Only single-byte codes reach it, and that is not an optimization. Emacs-Mule and the
     * stateless ISO-2022-JP variants answer every ctype query for a multi-byte code with true
     * (EmacsMuleEncoding returns codeToMbcLength(code) > 1 whatever ctype is asked for), and wide
     * GB18030 codepoints arrive negative in a signed int. Falling back to the switch loses
     * nothing: in an ASCII-compatible encoding a multi-byte codepoint always starts at 0x8000 or
     * above, past the U+3000 the switch tops out at, so it only ever answers "not blank" there.
     */
    private static boolean isBlankCodepoint(int codepoint, Encoding enc) {
        if (enc.isUnicode() || codepoint < 0 || codepoint > MAX_CTYPE_CODEPOINT) {
            return isUnicodeBlank(codepoint);
        }
        return enc.isSpace(codepoint);
    }

    /*
     * Handles the rest of an ASCII-compatible string once its first non-ASCII byte is found: ASCII
     * runs stay on the bytewise scan and only non-ASCII characters go through the decoder. The
     * decoder is entered only on character boundaries: every byte the bytewise scan steps over is
     * a single-byte character, and decoded characters are skipped whole.
     *
     * blankUnicodeSlow stays for what this cannot serve: where the encoding is not
     * ASCII-compatible, a byte below 0x80 is not a character on its own, so every character has to
     * go through the decoder.
     */
    private static IRubyObject blankMixed(
            ThreadContext context, RubyString str, byte[] bytes, int s, int e, Encoding enc) {
        while (s < e) {
            byte c = bytes[s];
            if (c >= 0) {
                if (!isAsciiBlank(c)) {
                    return context.fals;
                }
                s++;
                continue;
            }
            int length = StringSupport.preciseLength(enc, bytes, s, e);
            if (!StringSupport.MBCLEN_CHARFOUND_P(length)) {
                return blankUndecodable(context, str, enc);
            }
            int codepoint = enc.mbcToCode(bytes, s, e);
            if (!isBlankCodepoint(codepoint, enc)) {
                return context.fals;
            }
            s += StringSupport.MBCLEN_CHARFOUND_LEN(length);
        }

        return context.tru;
    }

    private static IRubyObject blankUnicodeSlow(
            ThreadContext context, RubyString str, byte[] bytes, int s, int e, Encoding enc) {
        while (s < e) {
            int length = StringSupport.preciseLength(enc, bytes, s, e);
            if (!StringSupport.MBCLEN_CHARFOUND_P(length)) {
                return blankUndecodable(context, str, enc);
            }
            int codepoint = enc.mbcToCode(bytes, s, e);
            if (!isBlankCodepoint(codepoint, enc)) {
                return context.fals;
            }
            s += StringSupport.MBCLEN_CHARFOUND_LEN(length);
        }

        return context.tru;
    }

    /*
     * Reached when the scanner cannot decode the bytes ahead. ActiveSupport's regexp never rescans:
     * it trusts the code range Ruby cached on the string, so it raises only for a string Ruby itself
     * calls broken, and answers "not blank" for one whose transcoder and scanner disagree. Reading
     * the cached code range costs nothing; computing an uncomputed one would scan the whole string,
     * give up the early exit this loop exists for, and only ever come out broken anyway, since it
     * runs the decode that just failed here.
     */
    private static IRubyObject blankUndecodable(
            ThreadContext context, RubyString str, Encoding enc) {
        if (str.getCodeRange() == StringSupport.CR_VALID) {
            return context.fals;
        }
        throw context.runtime.newArgumentError("invalid byte sequence in " + enc);
    }

    @JRubyMethod(name = "ascii_blank?")
    public static IRubyObject ascii_blank_p(ThreadContext context, IRubyObject self) {
        RubyString str = (RubyString) self;
        ByteList byteList = str.getByteList();
        if (byteList.realSize() == 0) {
            return context.tru;
        }

        byte[] bytes = byteList.unsafeBytes();
        int s = byteList.begin();
        int e = s + byteList.realSize();
        Encoding enc = str.getEncoding();

        /*
         * This one never raises, because bytes that decode to nothing are no more an ASCII blank
         * than the characters they failed to form. An ASCII-compatible encoding does not even need
         * the decoder: a byte of 0x80 or above only ever starts a character whose codepoint is 0x80
         * or above there, so the first one settles the answer.
         */
        if (enc.isAsciiCompatible()) {
            for (int i = s; i < e; i++) {
                if (!isAsciiBlankOrNull(bytes[i])) {
                    return context.fals;
                }
            }
            return context.tru;
        }

        return asciiBlankUnicodeSlow(context, bytes, s, e, enc);
    }

    private static boolean isAsciiBlankOrNull(byte c) {
        return c == 0 || (c >= 0x09 && c <= 0x0d) || c == 0x20;
    }

    private static boolean isAsciiSpace(int codepoint) {
        return codepoint == ' ' || ('\t' <= codepoint && codepoint <= '\r');
    }

    private static IRubyObject asciiBlankUnicodeSlow(
            ThreadContext context, byte[] bytes, int s, int e, Encoding enc) {
        while (s < e) {
            int length = StringSupport.preciseLength(enc, bytes, s, e);
            if (!StringSupport.MBCLEN_CHARFOUND_P(length)) {
                return context.fals;
            }
            int codepoint = enc.mbcToCode(bytes, s, e);
            if (codepoint != 0 && !isAsciiSpace(codepoint)) {
                return context.fals;
            }
            s += StringSupport.MBCLEN_CHARFOUND_LEN(length);
        }

        return context.tru;
    }
}
