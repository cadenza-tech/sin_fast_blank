#include <ruby.h>
#include <ruby/encoding.h>

#define STR_ENC_GET(str) rb_enc_from_index(ENCODING_GET(str))

static inline int is_unicode_blank(unsigned int codepoint) {
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
      return 1;
    default:
      return 0;
  }
}

static VALUE rb_str_blank_as(VALUE str) {
  long len = RSTRING_LEN(str);
  if (len == 0) {
    return Qtrue;
  }

  const char *ptr = RSTRING_PTR(str);
  const char *end = ptr + len;
  rb_encoding *enc = STR_ENC_GET(str);

  if (rb_enc_asciicompat(enc)) {
    for (const unsigned char *p = (const unsigned char *)ptr; p < (const unsigned char *)end; p++) {
      if (*p >= 0x80) {
        goto FULL_CHECK;
      }

      switch (*p) {
        case 0x9:
        case 0xa:
        case 0xb:
        case 0xc:
        case 0xd:
        case 0x20:
          break;
        default:
          return Qfalse;
      }
    }

    return Qtrue;
  }

FULL_CHECK:;
  while (ptr < end) {
    int clen;
    unsigned int codepoint = rb_enc_codepoint_len(ptr, end, &clen, enc);

    if (!is_unicode_blank(codepoint)) {
      return Qfalse;
    }

    ptr += clen;
  }

  return Qtrue;
}

static VALUE rb_str_blank(VALUE str) {
  long len = RSTRING_LEN(str);
  if (len == 0) {
    return Qtrue;
  }

  const char *ptr = RSTRING_PTR(str);
  const char *end = ptr + len;
  rb_encoding *enc = STR_ENC_GET(str);

  if (rb_enc_asciicompat(enc)) {
    for (; ptr < end; ptr++) {
      unsigned char c = (unsigned char)*ptr;

      if (c >= 0x80) {
        goto FULL_CHECK;
      }

      if (!rb_isspace(c) && c != 0) {
        return Qfalse;
      }
    }

    return Qtrue;
  }

FULL_CHECK:;
  while (ptr < end) {
    int clen;
    unsigned int codepoint = rb_enc_codepoint_len(ptr, end, &clen, enc);

    if (codepoint != 0 && !rb_isspace(codepoint)) {
      return Qfalse;
    }

    ptr += clen;
  }

  return Qtrue;
}

void Init_sin_fast_blank(void) {
  rb_define_method(rb_cString, "blank?", rb_str_blank, 0);
  rb_define_method(rb_cString, "blank_as?", rb_str_blank_as, 0);
}
