#include <ruby.h>
#include <ruby/encoding.h>

#define STR_ENC_GET(str) rb_enc_from_index(ENCODING_GET(str))

static VALUE rb_str_blank_as(VALUE str) {
  char *ptr = RSTRING_PTR(str);
  if (!ptr || RSTRING_LEN(str) == 0) return Qtrue;

  char *end = RSTRING_END(str);
  rb_encoding *enc = STR_ENC_GET(str);

  while (ptr < end) {
    int len;
    unsigned int codepoint = rb_enc_codepoint_len(ptr, end, &len, enc);

    switch (codepoint) {
      case 9:
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
        break;
      default:
        return Qfalse;
    }

    ptr += len;
  }

  return Qtrue;
}

static VALUE rb_str_blank(VALUE str) {
  char *ptr = RSTRING_PTR(str);
  if (!ptr || RSTRING_LEN(str) == 0) return Qtrue;

  char *end = RSTRING_END(str);
  rb_encoding *enc = STR_ENC_GET(str);
  while (ptr < end) {
    int len;
    unsigned int codepoint = rb_enc_codepoint_len(ptr, end, &len, enc);

    if (!rb_isspace(codepoint) && codepoint != 0) return Qfalse;

    ptr += len;
  }

  return Qtrue;
}

void Init_sin_fast_blank(void) {
  rb_define_method(rb_cString, "blank?", rb_str_blank, 0);
  rb_define_method(rb_cString, "blank_as?", rb_str_blank_as, 0);
}
