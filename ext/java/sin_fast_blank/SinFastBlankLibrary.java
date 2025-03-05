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
import org.jruby.util.io.EncodingUtils;

public class SinFastBlankLibrary implements Library {
    @Override
    public void load(Ruby runtime, boolean wrap) {
        runtime.getString().defineAnnotatedMethods(SinFastBlankLibrary.class);
    }

    @JRubyMethod(name = "blank?")
    public static IRubyObject blank_p(ThreadContext context, IRubyObject self) {
        RubyString str = (RubyString) self;
        if (str.size() == 0) {
            return context.tru;
        }

        ByteList sByteList = str.getByteList();
        byte[] sBytes = sByteList.unsafeBytes();
        int s = sByteList.begin();
        int e = s + sByteList.realSize();

        if (str.getCodeRange() == StringSupport.CR_7BIT) {
            for (int i = s; i < e; i++) {
                byte c = sBytes[i];
                if (!isAsciiBlankAs(c)) {
                    return context.fals;
                }
            }

            return context.tru;
        }

        return blankAsSlow(context, sBytes, s, e, str.getEncoding());
    }

    private static boolean isAsciiBlankAs(byte c) {
        switch (c) {
            case 0x9:
            case 0xa:
            case 0xb:
            case 0xc:
            case 0xd:
            case 0x20:
                return true;
            default:
                return false;
        }
    }

    private static IRubyObject blankAsSlow(ThreadContext context, byte[] bytes, int s, int e, Encoding enc) {
        Ruby runtime = context.runtime;
        int[] len = {0};

        while (s < e) {
            int codepoint = EncodingUtils.encCodepointLength(runtime, bytes, s, e, len, enc);

            if (!isUnicodeBlankAs(codepoint)) {
                return context.fals;
            }

            s += len[0];
        }

        return context.tru;
    }

    private static boolean isUnicodeBlankAs(int codepoint) {
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

    @JRubyMethod(name = "ascii_blank?")
    public static IRubyObject ascii_blank_p(ThreadContext context, IRubyObject self) {
        RubyString str = (RubyString) self;
        if (str.size() == 0) {
            return context.tru;
        }

        ByteList sByteList = str.getByteList();
        byte[] sBytes = sByteList.unsafeBytes();
        int s = sByteList.begin();
        int e = s + sByteList.realSize();

        if (str.getCodeRange() == StringSupport.CR_7BIT) {
            for (int i = s; i < e; i++) {
                if (!isSpace(sBytes[i])) {
                    return context.fals;
                }
            }

            return context.tru;
        }

        return blankSlow(context, sBytes, s, e, str.getEncoding());
    }

    private static IRubyObject blankSlow(ThreadContext context, byte[] bytes, int s, int e, Encoding enc) {
        Ruby runtime = context.runtime;
        int[] len = {0};

        while (s < e) {
            int codepoint = EncodingUtils.encCodepointLength(runtime, bytes, s, e, len, enc);

            if (codepoint != 0 && !isSpaceCodepoint(codepoint)) {
                return context.fals;
            }

            s += len[0];
        }

        return context.tru;
    }

    private static boolean isSpaceCodepoint(int codepoint) {
        return codepoint == ' ' || ('\t' <= codepoint && codepoint <= '\r');
    }

    private static boolean isSpace(byte c) {
        return c == ' ' || ('\t' <= c && c <= '\r') || c == '\0';
    }
}
