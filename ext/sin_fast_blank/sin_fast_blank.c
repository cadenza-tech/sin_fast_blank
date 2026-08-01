#include <ruby.h>
#include <ruby/encoding.h>
#include <stdbool.h>

#if defined(__SSE2__)
#define SIN_FAST_BLANK_SSE2 1
#endif

/*
 * __AVX2__: the user opted in with -mavx2/-march=native, so every AVX2 helper can be compiled directly.
 * HAVE_AVX2_RUNTIME_DISPATCH (from extconf.rb): only the helpers marked with __attribute__((target("avx2"))) use AVX2 and
 * Init_sin_fast_blank selects them via __builtin_cpu_supports, so the binary stays safe on CPUs without AVX2.
 */
#if defined(__AVX2__)
#define SIN_FAST_BLANK_AVX2 1
#define SIN_FAST_BLANK_AVX2_TARGET
#elif defined(HAVE_AVX2_RUNTIME_DISPATCH) && defined(SIN_FAST_BLANK_SSE2) && (defined(__GNUC__) || defined(__clang__))
#define SIN_FAST_BLANK_AVX2 1
#define SIN_FAST_BLANK_AVX2_DISPATCH 1
#define SIN_FAST_BLANK_AVX2_TARGET __attribute__((target("avx2")))
#endif

#if defined(SIN_FAST_BLANK_SSE2)
#include <emmintrin.h>
#endif
#if defined(SIN_FAST_BLANK_AVX2)
#include <immintrin.h>
#endif
#if defined(__ARM_NEON) && defined(__aarch64__)
#define SIN_FAST_BLANK_NEON 1
#include <arm_neon.h>
#endif

#define STR_ENC_GET(str) rb_enc_from_index(ENCODING_GET(str))

#define ASCII_WS_RANGE_MIN 0x09
#define ASCII_WS_RANGE_MAX 0x0d
#define ASCII_WS_SPACE 0x20

static inline bool is_ascii_blank_char(unsigned char c) { return (c >= ASCII_WS_RANGE_MIN && c <= ASCII_WS_RANGE_MAX) || c == ASCII_WS_SPACE; }

static inline bool is_ascii_blank_or_null_char(unsigned char c) {
  return c == 0x00 || (c >= ASCII_WS_RANGE_MIN && c <= ASCII_WS_RANGE_MAX) || c == ASCII_WS_SPACE;
}

static inline bool is_unicode_blank(unsigned int codepoint) {
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

/* Returns true if all blank. On false, sets *non_ascii_pos if non-ASCII found. NULL if non-blank ASCII found. */
static inline bool scan_ascii_blank(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
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

static inline bool scan_ascii_blank_or_null(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
  for (size_t i = 0; i < len; i++) {
    unsigned char c = ptr[i];
    if (c >= 0x80) {
      *non_ascii_pos = ptr + i;
      return false;
    }
    if (!is_ascii_blank_or_null_char(c)) {
      return false;
    }
  }
  return true;
}

#if defined(SIN_FAST_BLANK_AVX2)
SIN_FAST_BLANK_AVX2_TARGET static bool check_blank_avx2(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
  const __m256i ws_base = _mm256_set1_epi8(ASCII_WS_RANGE_MIN);
  const __m256i four = _mm256_set1_epi8(ASCII_WS_RANGE_MAX - ASCII_WS_RANGE_MIN);
  const __m256i space = _mm256_set1_epi8(ASCII_WS_SPACE);

  size_t i = 0;
  for (; i + 31 < len; i += 32) {
    __m256i chunk = _mm256_loadu_si256((const __m256i*)(ptr + i));
    __m256i adjusted = _mm256_sub_epi8(chunk, ws_base);
    __m256i in_range = _mm256_cmpeq_epi8(_mm256_min_epu8(adjusted, four), adjusted);
    __m256i is_sp = _mm256_cmpeq_epi8(chunk, space);
    __m256i is_blank = _mm256_or_si256(in_range, is_sp);

    int mask = _mm256_movemask_epi8(is_blank);
    if (mask != -1) {
      int first = __builtin_ctz(~mask);
      unsigned char c = ptr[i + first];
      if (c >= 0x80) {
        *non_ascii_pos = ptr + i + first;
      }
      return false;
    }
  }

  return scan_ascii_blank(ptr + i, len - i, non_ascii_pos);
}

SIN_FAST_BLANK_AVX2_TARGET static bool check_ascii_blank_avx2(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
  const __m256i ws_base = _mm256_set1_epi8(ASCII_WS_RANGE_MIN);
  const __m256i four = _mm256_set1_epi8(ASCII_WS_RANGE_MAX - ASCII_WS_RANGE_MIN);
  const __m256i space = _mm256_set1_epi8(ASCII_WS_SPACE);
  const __m256i zero = _mm256_setzero_si256();

  size_t i = 0;
  for (; i + 31 < len; i += 32) {
    __m256i chunk = _mm256_loadu_si256((const __m256i*)(ptr + i));
    __m256i adjusted = _mm256_sub_epi8(chunk, ws_base);
    __m256i in_range = _mm256_cmpeq_epi8(_mm256_min_epu8(adjusted, four), adjusted);
    __m256i is_sp = _mm256_cmpeq_epi8(chunk, space);
    __m256i is_null = _mm256_cmpeq_epi8(chunk, zero);
    __m256i is_blank = _mm256_or_si256(_mm256_or_si256(in_range, is_sp), is_null);

    int mask = _mm256_movemask_epi8(is_blank);
    if (mask != -1) {
      int first = __builtin_ctz(~mask);
      unsigned char c = ptr[i + first];
      if (c >= 0x80) {
        *non_ascii_pos = ptr + i + first;
      }
      return false;
    }
  }

  return scan_ascii_blank_or_null(ptr + i, len - i, non_ascii_pos);
}
#endif

#if defined(SIN_FAST_BLANK_SSE2)
static bool check_blank_sse2(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
  const __m128i ws_base = _mm_set1_epi8(ASCII_WS_RANGE_MIN);
  const __m128i four = _mm_set1_epi8(ASCII_WS_RANGE_MAX - ASCII_WS_RANGE_MIN);
  const __m128i space = _mm_set1_epi8(ASCII_WS_SPACE);

  size_t i = 0;
  for (; i + 15 < len; i += 16) {
    __m128i chunk = _mm_loadu_si128((const __m128i*)(ptr + i));
    __m128i adjusted = _mm_sub_epi8(chunk, ws_base);
    __m128i in_range = _mm_cmpeq_epi8(_mm_min_epu8(adjusted, four), adjusted);
    __m128i is_sp = _mm_cmpeq_epi8(chunk, space);
    __m128i is_blank = _mm_or_si128(in_range, is_sp);

    int mask = _mm_movemask_epi8(is_blank);
    if (mask != 0xFFFF) {
      int first = __builtin_ctz(~mask & 0xFFFF);
      unsigned char c = ptr[i + first];
      if (c >= 0x80) {
        *non_ascii_pos = ptr + i + first;
      }
      return false;
    }
  }

  return scan_ascii_blank(ptr + i, len - i, non_ascii_pos);
}

static bool check_ascii_blank_sse2(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
  const __m128i ws_base = _mm_set1_epi8(ASCII_WS_RANGE_MIN);
  const __m128i four = _mm_set1_epi8(ASCII_WS_RANGE_MAX - ASCII_WS_RANGE_MIN);
  const __m128i space = _mm_set1_epi8(ASCII_WS_SPACE);
  const __m128i zero = _mm_setzero_si128();

  size_t i = 0;
  for (; i + 15 < len; i += 16) {
    __m128i chunk = _mm_loadu_si128((const __m128i*)(ptr + i));
    __m128i adjusted = _mm_sub_epi8(chunk, ws_base);
    __m128i in_range = _mm_cmpeq_epi8(_mm_min_epu8(adjusted, four), adjusted);
    __m128i is_sp = _mm_cmpeq_epi8(chunk, space);
    __m128i is_null = _mm_cmpeq_epi8(chunk, zero);
    __m128i is_blank = _mm_or_si128(_mm_or_si128(in_range, is_sp), is_null);

    int mask = _mm_movemask_epi8(is_blank);
    if (mask != 0xFFFF) {
      int first = __builtin_ctz(~mask & 0xFFFF);
      unsigned char c = ptr[i + first];
      if (c >= 0x80) {
        *non_ascii_pos = ptr + i + first;
      }
      return false;
    }
  }

  return scan_ascii_blank_or_null(ptr + i, len - i, non_ascii_pos);
}
#endif

#if defined(SIN_FAST_BLANK_NEON)
static bool check_blank_neon(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
  const uint8x16_t ws_base = vdupq_n_u8(ASCII_WS_RANGE_MIN);
  const uint8x16_t four = vdupq_n_u8(ASCII_WS_RANGE_MAX - ASCII_WS_RANGE_MIN);
  const uint8x16_t space = vdupq_n_u8(ASCII_WS_SPACE);

  size_t i = 0;
  for (; i + 15 < len; i += 16) {
    uint8x16_t chunk = vld1q_u8(ptr + i);
    uint8x16_t adjusted = vsubq_u8(chunk, ws_base);
    uint8x16_t in_range = vceqq_u8(vminq_u8(adjusted, four), adjusted);
    uint8x16_t is_sp = vceqq_u8(chunk, space);
    uint8x16_t is_blank = vorrq_u8(in_range, is_sp);

    if (vminvq_u8(is_blank) == 0) {
      if (!scan_ascii_blank(ptr + i, 16, non_ascii_pos)) return false;
    }
  }

  return scan_ascii_blank(ptr + i, len - i, non_ascii_pos);
}

static bool check_ascii_blank_neon(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
  const uint8x16_t ws_base = vdupq_n_u8(ASCII_WS_RANGE_MIN);
  const uint8x16_t four = vdupq_n_u8(ASCII_WS_RANGE_MAX - ASCII_WS_RANGE_MIN);
  const uint8x16_t space = vdupq_n_u8(ASCII_WS_SPACE);
  const uint8x16_t zero = vdupq_n_u8(0);

  size_t i = 0;
  for (; i + 15 < len; i += 16) {
    uint8x16_t chunk = vld1q_u8(ptr + i);
    uint8x16_t adjusted = vsubq_u8(chunk, ws_base);
    uint8x16_t in_range = vceqq_u8(vminq_u8(adjusted, four), adjusted);
    uint8x16_t is_sp = vceqq_u8(chunk, space);
    uint8x16_t is_null = vceqq_u8(chunk, zero);
    uint8x16_t is_blank = vorrq_u8(vorrq_u8(in_range, is_sp), is_null);

    if (vminvq_u8(is_blank) == 0) {
      if (!scan_ascii_blank_or_null(ptr + i, 16, non_ascii_pos)) return false;
    }
  }

  return scan_ascii_blank_or_null(ptr + i, len - i, non_ascii_pos);
}
#endif

#if !defined(SIN_FAST_BLANK_AVX2) && !defined(SIN_FAST_BLANK_SSE2) && !defined(SIN_FAST_BLANK_NEON)
static bool check_blank_scalar(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
  return scan_ascii_blank(ptr, len, non_ascii_pos);
}

static bool check_ascii_blank_scalar(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
  return scan_ascii_blank_or_null(ptr, len, non_ascii_pos);
}
#endif

#if defined(SIN_FAST_BLANK_AVX2_DISPATCH)
typedef bool (*blank_check_func)(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos);

/* Written once by Init_sin_fast_blank before the methods become callable, read-only afterwards. */
static blank_check_func check_blank_dispatch = check_blank_sse2;
static blank_check_func check_ascii_blank_dispatch = check_ascii_blank_sse2;
#endif

static inline bool check_blank(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
#if defined(SIN_FAST_BLANK_AVX2_DISPATCH)
  return check_blank_dispatch(ptr, len, non_ascii_pos);
#elif defined(SIN_FAST_BLANK_AVX2)
  return check_blank_avx2(ptr, len, non_ascii_pos);
#elif defined(SIN_FAST_BLANK_SSE2)
  return check_blank_sse2(ptr, len, non_ascii_pos);
#elif defined(SIN_FAST_BLANK_NEON)
  return check_blank_neon(ptr, len, non_ascii_pos);
#else
  return check_blank_scalar(ptr, len, non_ascii_pos);
#endif
}

static inline bool check_ascii_blank(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
#if defined(SIN_FAST_BLANK_AVX2_DISPATCH)
  return check_ascii_blank_dispatch(ptr, len, non_ascii_pos);
#elif defined(SIN_FAST_BLANK_AVX2)
  return check_ascii_blank_avx2(ptr, len, non_ascii_pos);
#elif defined(SIN_FAST_BLANK_SSE2)
  return check_ascii_blank_sse2(ptr, len, non_ascii_pos);
#elif defined(SIN_FAST_BLANK_NEON)
  return check_ascii_blank_neon(ptr, len, non_ascii_pos);
#else
  return check_ascii_blank_scalar(ptr, len, non_ascii_pos);
#endif
}

static VALUE rb_str_blank(VALUE str) {
  long len = RSTRING_LEN(str);
  if (len == 0) return Qtrue;

  const unsigned char* ptr = (const unsigned char*)RSTRING_PTR(str);
  const unsigned char* end = ptr + len;
  rb_encoding* enc = STR_ENC_GET(str);

  if (rb_enc_asciicompat(enc)) {
    const unsigned char* non_ascii_pos = NULL;

    if (check_blank(ptr, (size_t)len, &non_ascii_pos)) return Qtrue;
    if (non_ascii_pos == NULL) return Qfalse;

    ptr = non_ascii_pos;
  }

  while (ptr < end) {
    int clen;
    unsigned int codepoint = rb_enc_codepoint_len((const char*)ptr, (const char*)end, &clen, enc);
    if (!is_unicode_blank(codepoint)) return Qfalse;
    ptr += clen;
  }

  return Qtrue;
}

static VALUE rb_str_ascii_blank(VALUE str) {
  long len = RSTRING_LEN(str);
  if (len == 0) return Qtrue;

  const unsigned char* ptr = (const unsigned char*)RSTRING_PTR(str);
  const unsigned char* end = ptr + len;
  rb_encoding* enc = STR_ENC_GET(str);

  if (rb_enc_asciicompat(enc)) {
    const unsigned char* non_ascii_pos = NULL;

    if (check_ascii_blank(ptr, (size_t)len, &non_ascii_pos)) return Qtrue;
    if (non_ascii_pos == NULL) return Qfalse;

    ptr = non_ascii_pos;
  }

  while (ptr < end) {
    int clen;
    unsigned int codepoint = rb_enc_codepoint_len((const char*)ptr, (const char*)end, &clen, enc);
    if (codepoint != 0 && !rb_isspace(codepoint)) return Qfalse;
    ptr += clen;
  }

  return Qtrue;
}

void Init_sin_fast_blank(void) {
#if defined(SIN_FAST_BLANK_AVX2_DISPATCH)
  if (__builtin_cpu_supports("avx2")) {
    check_blank_dispatch = check_blank_avx2;
    check_ascii_blank_dispatch = check_ascii_blank_avx2;
  }
#endif

  rb_define_method(rb_cString, "blank?", rb_str_blank, 0);
  rb_define_method(rb_cString, "ascii_blank?", rb_str_ascii_blank, 0);
}
