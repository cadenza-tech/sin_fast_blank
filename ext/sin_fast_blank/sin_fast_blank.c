#include <ruby.h>
#include <ruby/encoding.h>
#include <stdbool.h>
#ifdef __SSE2__
  #include <emmintrin.h>
#endif
#ifdef __AVX2__
  #include <immintrin.h>
#endif
#ifdef __ARM_NEON
  #include <arm_neon.h>
#endif

#define STR_ENC_GET(str) rb_enc_from_index(ENCODING_GET(str))

#define ASCII_BLANK_TAB 0x09
#define ASCII_BLANK_LF 0x0a
#define ASCII_BLANK_VT 0x0b
#define ASCII_BLANK_FF 0x0c
#define ASCII_BLANK_CR 0x0d
#define ASCII_BLANK_SPACE 0x20

static inline bool is_ascii_blank_char(unsigned char c) {
  return c == ASCII_BLANK_SPACE ||
         c == ASCII_BLANK_TAB ||
         c == ASCII_BLANK_LF ||
         c == ASCII_BLANK_VT ||
         c == ASCII_BLANK_FF ||
         c == ASCII_BLANK_CR;
}

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

#ifdef __AVX2__
static bool check_blank_avx2(const unsigned char *ptr, size_t len, const unsigned char **non_ascii_pos) {
  const __m256i ascii_mask = _mm256_set1_epi8(0x80);
  const __m256i space = _mm256_set1_epi8(ASCII_BLANK_SPACE);
  const __m256i tab = _mm256_set1_epi8(ASCII_BLANK_TAB);
  const __m256i lf = _mm256_set1_epi8(ASCII_BLANK_LF);
  const __m256i vt = _mm256_set1_epi8(ASCII_BLANK_VT);
  const __m256i ff = _mm256_set1_epi8(ASCII_BLANK_FF);
  const __m256i cr = _mm256_set1_epi8(ASCII_BLANK_CR);

  size_t i = 0;

  for (; i + 31 < len; i += 32) {
    __m256i chunk = _mm256_loadu_si256((const __m256i *)(ptr + i));

    __m256i non_ascii = _mm256_and_si256(chunk, ascii_mask);
    if (!_mm256_testz_si256(non_ascii, non_ascii)) {
      for (size_t j = 0; j < 32; j++) {
        if (ptr[i + j] >= 0x80) {
          *non_ascii_pos = ptr + i + j;
          return false;
        }
      }
    }

    __m256i is_space = _mm256_cmpeq_epi8(chunk, space);
    __m256i is_tab = _mm256_cmpeq_epi8(chunk, tab);
    __m256i is_lf = _mm256_cmpeq_epi8(chunk, lf);
    __m256i is_vt = _mm256_cmpeq_epi8(chunk, vt);
    __m256i is_ff = _mm256_cmpeq_epi8(chunk, ff);
    __m256i is_cr = _mm256_cmpeq_epi8(chunk, cr);

    __m256i is_blank = _mm256_or_si256(is_space, is_tab);
    is_blank = _mm256_or_si256(is_blank, is_lf);
    is_blank = _mm256_or_si256(is_blank, is_vt);
    is_blank = _mm256_or_si256(is_blank, is_ff);
    is_blank = _mm256_or_si256(is_blank, is_cr);

    if (_mm256_movemask_epi8(is_blank) != -1) {
      for (size_t j = 0; j < 32; j++) {
        unsigned char c = ptr[i + j];
        if (c >= 0x80) {
          *non_ascii_pos = ptr + i + j;
          return false;
        }
        if (!is_ascii_blank_char(c)) {
          return false;
        }
      }
    }
  }

  for (; i < len; i++) {
    unsigned char c = ptr[i];
    if (c >= 0x80) {
      *non_ascii_pos = ptr + i;
      return false;
    }
    if (!is_ascii_blank_char(c)) {
      return false;
    }
  }

  return true;
}
#endif

#ifdef __SSE2__
static bool check_blank_sse2(const unsigned char *ptr, size_t len, const unsigned char **non_ascii_pos) {
  const __m128i ascii_mask = _mm_set1_epi8(0x80);
  const __m128i space = _mm_set1_epi8(ASCII_BLANK_SPACE);
  const __m128i tab = _mm_set1_epi8(ASCII_BLANK_TAB);
  const __m128i lf = _mm_set1_epi8(ASCII_BLANK_LF);
  const __m128i vt = _mm_set1_epi8(ASCII_BLANK_VT);
  const __m128i ff = _mm_set1_epi8(ASCII_BLANK_FF);
  const __m128i cr = _mm_set1_epi8(ASCII_BLANK_CR);

  size_t i = 0;

  for (; i + 15 < len; i += 16) {
    __m128i chunk = _mm_loadu_si128((const __m128i *)(ptr + i));

    __m128i non_ascii = _mm_and_si128(chunk, ascii_mask);
    if (_mm_movemask_epi8(non_ascii) != 0) {
      for (size_t j = 0; j < 16; j++) {
        if (ptr[i + j] >= 0x80) {
          *non_ascii_pos = ptr + i + j;
          return false;
        }
      }
    }

    __m128i is_space = _mm_cmpeq_epi8(chunk, space);
    __m128i is_tab = _mm_cmpeq_epi8(chunk, tab);
    __m128i is_lf = _mm_cmpeq_epi8(chunk, lf);
    __m128i is_vt = _mm_cmpeq_epi8(chunk, vt);
    __m128i is_ff = _mm_cmpeq_epi8(chunk, ff);
    __m128i is_cr = _mm_cmpeq_epi8(chunk, cr);

    __m128i is_blank = _mm_or_si128(is_space, is_tab);
    is_blank = _mm_or_si128(is_blank, is_lf);
    is_blank = _mm_or_si128(is_blank, is_vt);
    is_blank = _mm_or_si128(is_blank, is_ff);
    is_blank = _mm_or_si128(is_blank, is_cr);

    if (_mm_movemask_epi8(is_blank) != 0xFFFF) {
      for (size_t j = 0; j < 16; j++) {
        unsigned char c = ptr[i + j];
        if (c >= 0x80) {
          *non_ascii_pos = ptr + i + j;
          return false;
        }
        if (!is_ascii_blank_char(c)) {
          return false;
        }
      }
    }
  }

  for (; i < len; i++) {
    unsigned char c = ptr[i];
    if (c >= 0x80) {
      *non_ascii_pos = ptr + i;
      return false;
    }
    if (!is_ascii_blank_char(c)) {
      return false;
    }
  }

  return true;
}
#endif

#ifdef __ARM_NEON
static bool check_blank_neon(const unsigned char *ptr, size_t len, const unsigned char **non_ascii_pos) {
  const uint8x16_t ascii_mask = vdupq_n_u8(0x80);
  const uint8x16_t space = vdupq_n_u8(ASCII_BLANK_SPACE);
  const uint8x16_t tab = vdupq_n_u8(ASCII_BLANK_TAB);
  const uint8x16_t lf = vdupq_n_u8(ASCII_BLANK_LF);
  const uint8x16_t vt = vdupq_n_u8(ASCII_BLANK_VT);
  const uint8x16_t ff = vdupq_n_u8(ASCII_BLANK_FF);
  const uint8x16_t cr = vdupq_n_u8(ASCII_BLANK_CR);

  size_t i = 0;

  for (; i + 15 < len; i += 16) {
    uint8x16_t chunk = vld1q_u8(ptr + i);

    uint8x16_t non_ascii = vandq_u8(chunk, ascii_mask);
    uint8x16_t has_non_ascii = vceqq_u8(non_ascii, ascii_mask);

    if (vmaxvq_u8(has_non_ascii) != 0) {
      for (size_t j = 0; j < 16; j++) {
        if (ptr[i + j] >= 0x80) {
          *non_ascii_pos = ptr + i + j;
          return false;
        }
      }
    }

    uint8x16_t is_space = vceqq_u8(chunk, space);
    uint8x16_t is_tab = vceqq_u8(chunk, tab);
    uint8x16_t is_lf = vceqq_u8(chunk, lf);
    uint8x16_t is_vt = vceqq_u8(chunk, vt);
    uint8x16_t is_ff = vceqq_u8(chunk, ff);
    uint8x16_t is_cr = vceqq_u8(chunk, cr);

    uint8x16_t is_blank = vorrq_u8(is_space, is_tab);
    is_blank = vorrq_u8(is_blank, is_lf);
    is_blank = vorrq_u8(is_blank, is_vt);
    is_blank = vorrq_u8(is_blank, is_ff);
    is_blank = vorrq_u8(is_blank, is_cr);

    if (vminvq_u8(is_blank) == 0) {
      for (size_t j = 0; j < 16; j++) {
        unsigned char c = ptr[i + j];
        if (c >= 0x80) {
          *non_ascii_pos = ptr + i + j;
          return false;
        }
        if (!is_ascii_blank_char(c)) {
          return false;
        }
      }
    }
  }

  for (; i < len; i++) {
    unsigned char c = ptr[i];
    if (c >= 0x80) {
      *non_ascii_pos = ptr + i;
      return false;
    }
    if (!is_ascii_blank_char(c)) {
      return false;
    }
  }

  return true;
}
#endif

static bool check_blank_scalar(const unsigned char *ptr, size_t len, const unsigned char **non_ascii_pos) {
  for (size_t i = 0; i < len; i++) {
    unsigned char c = ptr[i];

    if (c >= 0x80) {
      *non_ascii_pos = ptr + i;
      return false;
    }

    if (!is_ascii_blank_char(c)) {
      return false;
    }
  }

  return true;
}

static VALUE rb_str_blank(VALUE str) {
  long len = RSTRING_LEN(str);
  if (len == 0) {
    return Qtrue;
  }

  const unsigned char *ptr = (const unsigned char *)RSTRING_PTR(str);
  const unsigned char *end = ptr + len;
  rb_encoding *enc = STR_ENC_GET(str);

  if (rb_enc_asciicompat(enc)) {
    const unsigned char *non_ascii_pos = NULL;
    bool is_blank = false;

#ifdef __AVX2__
    is_blank = check_blank_avx2(ptr, len, &non_ascii_pos);
#elif defined(__SSE2__)
    is_blank = check_blank_sse2(ptr, len, &non_ascii_pos);
#elif defined(__ARM_NEON)
    is_blank = check_blank_neon(ptr, len, &non_ascii_pos);
#else
    is_blank = check_blank_scalar(ptr, len, &non_ascii_pos);
#endif

    if (is_blank) {
      return Qtrue;
    }

    if (non_ascii_pos == NULL) {
      return Qfalse;
    }

    ptr = (const unsigned char *)non_ascii_pos;
  }

  while ((const char *)ptr < (const char *)end) {
    int clen;
    unsigned int codepoint = rb_enc_codepoint_len((const char *)ptr, (const char *)end, &clen, enc);

    if (!is_unicode_blank(codepoint)) {
      return Qfalse;
    }

    ptr += clen;
  }

  return Qtrue;
}

static VALUE rb_str_ascii_blank(VALUE str) {
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
  rb_define_method(rb_cString, "ascii_blank?", rb_str_ascii_blank, 0);
}
