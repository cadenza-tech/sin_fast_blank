#include <ruby.h>
#include <ruby/encoding.h>
#include <stdbool.h>
#include <string.h>

/* MSVC does not define __SSE2__, but SSE2 is part of the x64 ABI and of 32-bit /arch:SSE2 builds. */
#if defined(__SSE2__) || defined(_M_X64) || (defined(_M_IX86_FP) && _M_IX86_FP >= 2)
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

#if defined(SIN_FAST_BLANK_SSE2) || defined(SIN_FAST_BLANK_AVX2)
#if defined(_MSC_VER) && !defined(__clang__)
#include <intrin.h>
static inline int count_trailing_zeros(unsigned int value) {
  unsigned long index;
  _BitScanForward(&index, value);
  return (int)index;
}
#else
static inline int count_trailing_zeros(unsigned int value) { return __builtin_ctz(value); }
#endif
#endif

#define STR_ENC_GET(str) rb_enc_from_index(ENCODING_GET(str))

#define ASCII_WS_RANGE_MIN 0x09
#define ASCII_WS_RANGE_MAX 0x0d
#define ASCII_WS_SPACE 0x20
#define MAX_CTYPE_CODEPOINT 0xFF

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

/*
 * Matched by name because ONIGENC_IS_UNICODE() reads rb_encoding internals that other Ruby implementations may not expose. Every
 * Unicode encoding Ruby ships is named UTF-8, UTF-16*, UTF-32*, UTF8-* (the MAC and carrier replicas) or CESU-8.
 */
static inline bool is_unicode_encoding(rb_encoding* enc) {
  const char* name = rb_enc_name(enc);
  return strncmp(name, "UTF", 3) == 0 || strncmp(name, "CESU", 4) == 0;
}

/*
 * ActiveSupport's blank regexp matches [[:space:]] with the ctype table of the string's own encoding, which differs from the Unicode
 * table for some encodings (e.g. 0x85 is blank in UTF-8 but not in ISO-8859-1 or ASCII-8BIT). rb_enc_isspace() reads that same table.
 *
 * Only single-byte codes reach it, and that is not an optimization. TruffleRuby declares it as taking an unsigned char, so a wider
 * codepoint would be silently truncated, and Emacs-Mule and the stateless ISO-2022-JP variants answer every ctype query for a
 * multi-byte code with "true" (enc/emacs_mule.c returns code_to_mbclen(code) > 1 regardless of the ctype asked for). Falling back to
 * the switch loses nothing: in an ASCII-compatible encoding a multi-byte codepoint always starts at 0x8000 or above, past the U+3000
 * the switch tops out at, so it only ever answers "not blank" there.
 */
static inline bool is_blank_codepoint(unsigned int codepoint, rb_encoding* enc, bool is_unicode) {
  if (is_unicode || codepoint > MAX_CTYPE_CODEPOINT) return is_unicode_blank(codepoint);
  return rb_enc_isspace(codepoint, enc) != 0;
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

/* No non-ASCII position to report: a byte of 0x80 or above is not an ASCII blank either, so it settles the answer on its own. */
static inline bool scan_ascii_blank_or_null(const unsigned char* ptr, size_t len) {
  for (size_t i = 0; i < len; i++) {
    if (!is_ascii_blank_or_null_char(ptr[i])) {
      return false;
    }
  }
  return true;
}

/*
 * Every SIMD path below has the same shape: a chunk helper answers "is this whole chunk blank?" for one register of bytes, and a
 * check_*() walks the string chunk by chunk. The blank? helpers also hand back the first non-blank byte when it is non-ASCII, which is
 * where rb_str_blank() picks the decode up.
 *
 * The range test folds 0x09..0x0d into one comparison: the unsigned subtraction wraps every byte below 0x09 up past the span, so
 * min(c - 0x09, 0x04) == c - 0x09 holds inside the range and nowhere else. Space is compared on its own, and ascii_blank? adds NUL.
 *
 * The bytes left over when the length is not a whole number of chunks are covered by re-reading the final chunk at [len - chunk, len),
 * rather than walking them one at a time. What the re-read repeats is already known to be blank, so it cannot change the answer, and
 * measuring back from the end keeps the load inside the string. It does need a whole chunk to look back on, which is why each check_*()
 * hands anything shorter to the scalar scanner before the loop: that guard is what keeps the load in bounds, not a speed heuristic.
 */
#if defined(SIN_FAST_BLANK_SSE2)
static inline bool sse2_chunk_blank(const unsigned char* chunk_ptr, const unsigned char** non_ascii_pos) {
  const __m128i ws_base = _mm_set1_epi8(ASCII_WS_RANGE_MIN);
  const __m128i ws_span = _mm_set1_epi8(ASCII_WS_RANGE_MAX - ASCII_WS_RANGE_MIN);
  const __m128i space = _mm_set1_epi8(ASCII_WS_SPACE);

  __m128i chunk = _mm_loadu_si128((const __m128i*)chunk_ptr);
  __m128i adjusted = _mm_sub_epi8(chunk, ws_base);
  __m128i in_range = _mm_cmpeq_epi8(_mm_min_epu8(adjusted, ws_span), adjusted);
  __m128i is_sp = _mm_cmpeq_epi8(chunk, space);
  __m128i is_blank = _mm_or_si128(in_range, is_sp);

  int mask = _mm_movemask_epi8(is_blank);
  if (mask == 0xFFFF) return true;

  int first = count_trailing_zeros((unsigned int)(~mask & 0xFFFF));
  if (chunk_ptr[first] >= 0x80) {
    *non_ascii_pos = chunk_ptr + first;
  }
  return false;
}

static inline bool sse2_chunk_ascii_blank(const unsigned char* chunk_ptr) {
  const __m128i ws_base = _mm_set1_epi8(ASCII_WS_RANGE_MIN);
  const __m128i ws_span = _mm_set1_epi8(ASCII_WS_RANGE_MAX - ASCII_WS_RANGE_MIN);
  const __m128i space = _mm_set1_epi8(ASCII_WS_SPACE);

  __m128i chunk = _mm_loadu_si128((const __m128i*)chunk_ptr);
  __m128i adjusted = _mm_sub_epi8(chunk, ws_base);
  __m128i in_range = _mm_cmpeq_epi8(_mm_min_epu8(adjusted, ws_span), adjusted);
  __m128i is_sp = _mm_cmpeq_epi8(chunk, space);
  __m128i is_null = _mm_cmpeq_epi8(chunk, _mm_setzero_si128());
  __m128i is_blank = _mm_or_si128(_mm_or_si128(in_range, is_sp), is_null);

  return _mm_movemask_epi8(is_blank) == 0xFFFF;
}

static inline bool check_blank_sse2(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
  if (len < 16) return scan_ascii_blank(ptr, len, non_ascii_pos);

  size_t i = 0;
  for (; i + 16 <= len; i += 16) {
    if (!sse2_chunk_blank(ptr + i, non_ascii_pos)) return false;
  }
  if (i == len) return true;

  return sse2_chunk_blank(ptr + len - 16, non_ascii_pos);
}

static inline bool check_ascii_blank_sse2(const unsigned char* ptr, size_t len) {
  if (len < 16) return scan_ascii_blank_or_null(ptr, len);

  size_t i = 0;
  for (; i + 16 <= len; i += 16) {
    if (!sse2_chunk_ascii_blank(ptr + i)) return false;
  }
  if (i == len) return true;

  return sse2_chunk_ascii_blank(ptr + len - 16);
}
#endif

/* AVX2 implies SSE2 under both macro definitions above, so the sub-32-byte cases can fall back to the 16-byte chunks. */
#if defined(SIN_FAST_BLANK_AVX2)
SIN_FAST_BLANK_AVX2_TARGET static inline bool avx2_chunk_blank(const unsigned char* chunk_ptr, const unsigned char** non_ascii_pos) {
  const __m256i ws_base = _mm256_set1_epi8(ASCII_WS_RANGE_MIN);
  const __m256i ws_span = _mm256_set1_epi8(ASCII_WS_RANGE_MAX - ASCII_WS_RANGE_MIN);
  const __m256i space = _mm256_set1_epi8(ASCII_WS_SPACE);

  __m256i chunk = _mm256_loadu_si256((const __m256i*)chunk_ptr);
  __m256i adjusted = _mm256_sub_epi8(chunk, ws_base);
  __m256i in_range = _mm256_cmpeq_epi8(_mm256_min_epu8(adjusted, ws_span), adjusted);
  __m256i is_sp = _mm256_cmpeq_epi8(chunk, space);
  __m256i is_blank = _mm256_or_si256(in_range, is_sp);

  int mask = _mm256_movemask_epi8(is_blank);
  if (mask == -1) return true;

  int first = count_trailing_zeros(~(unsigned int)mask);
  if (chunk_ptr[first] >= 0x80) {
    *non_ascii_pos = chunk_ptr + first;
  }
  return false;
}

SIN_FAST_BLANK_AVX2_TARGET static inline bool avx2_chunk_ascii_blank(const unsigned char* chunk_ptr) {
  const __m256i ws_base = _mm256_set1_epi8(ASCII_WS_RANGE_MIN);
  const __m256i ws_span = _mm256_set1_epi8(ASCII_WS_RANGE_MAX - ASCII_WS_RANGE_MIN);
  const __m256i space = _mm256_set1_epi8(ASCII_WS_SPACE);

  __m256i chunk = _mm256_loadu_si256((const __m256i*)chunk_ptr);
  __m256i adjusted = _mm256_sub_epi8(chunk, ws_base);
  __m256i in_range = _mm256_cmpeq_epi8(_mm256_min_epu8(adjusted, ws_span), adjusted);
  __m256i is_sp = _mm256_cmpeq_epi8(chunk, space);
  __m256i is_null = _mm256_cmpeq_epi8(chunk, _mm256_setzero_si256());
  __m256i is_blank = _mm256_or_si256(_mm256_or_si256(in_range, is_sp), is_null);

  return _mm256_movemask_epi8(is_blank) == -1;
}

SIN_FAST_BLANK_AVX2_TARGET static bool check_blank_avx2(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
  if (len < 32) return check_blank_sse2(ptr, len, non_ascii_pos);

  size_t i = 0;
  for (; i + 32 <= len; i += 32) {
    if (!avx2_chunk_blank(ptr + i, non_ascii_pos)) return false;
  }
  if (i == len) return true;

  return avx2_chunk_blank(ptr + len - 32, non_ascii_pos);
}

SIN_FAST_BLANK_AVX2_TARGET static bool check_ascii_blank_avx2(const unsigned char* ptr, size_t len) {
  if (len < 32) return check_ascii_blank_sse2(ptr, len);

  size_t i = 0;
  for (; i + 32 <= len; i += 32) {
    if (!avx2_chunk_ascii_blank(ptr + i)) return false;
  }
  if (i == len) return true;

  return avx2_chunk_ascii_blank(ptr + len - 32);
}
#endif

#if defined(SIN_FAST_BLANK_NEON)
static inline bool neon_chunk_blank(const unsigned char* chunk_ptr, const unsigned char** non_ascii_pos) {
  const uint8x16_t ws_base = vdupq_n_u8(ASCII_WS_RANGE_MIN);
  const uint8x16_t ws_span = vdupq_n_u8(ASCII_WS_RANGE_MAX - ASCII_WS_RANGE_MIN);
  const uint8x16_t space = vdupq_n_u8(ASCII_WS_SPACE);

  uint8x16_t chunk = vld1q_u8(chunk_ptr);
  uint8x16_t adjusted = vsubq_u8(chunk, ws_base);
  uint8x16_t in_range = vceqq_u8(vminq_u8(adjusted, ws_span), adjusted);
  uint8x16_t is_sp = vceqq_u8(chunk, space);
  uint8x16_t is_blank = vorrq_u8(in_range, is_sp);

  if (vminvq_u8(is_blank) != 0) return true;

  /* NEON has no movemask, so the scalar scanner locates the first non-blank byte. It cannot report true here. */
  return scan_ascii_blank(chunk_ptr, 16, non_ascii_pos);
}

static inline bool neon_chunk_ascii_blank(const unsigned char* chunk_ptr) {
  const uint8x16_t ws_base = vdupq_n_u8(ASCII_WS_RANGE_MIN);
  const uint8x16_t ws_span = vdupq_n_u8(ASCII_WS_RANGE_MAX - ASCII_WS_RANGE_MIN);
  const uint8x16_t space = vdupq_n_u8(ASCII_WS_SPACE);

  uint8x16_t chunk = vld1q_u8(chunk_ptr);
  uint8x16_t adjusted = vsubq_u8(chunk, ws_base);
  uint8x16_t in_range = vceqq_u8(vminq_u8(adjusted, ws_span), adjusted);
  uint8x16_t is_sp = vceqq_u8(chunk, space);
  uint8x16_t is_null = vceqq_u8(chunk, vdupq_n_u8(0));
  uint8x16_t is_blank = vorrq_u8(vorrq_u8(in_range, is_sp), is_null);

  return vminvq_u8(is_blank) != 0;
}

static bool check_blank_neon(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
  if (len < 16) return scan_ascii_blank(ptr, len, non_ascii_pos);

  size_t i = 0;
  for (; i + 16 <= len; i += 16) {
    if (!neon_chunk_blank(ptr + i, non_ascii_pos)) return false;
  }
  if (i == len) return true;

  return neon_chunk_blank(ptr + len - 16, non_ascii_pos);
}

static bool check_ascii_blank_neon(const unsigned char* ptr, size_t len) {
  if (len < 16) return scan_ascii_blank_or_null(ptr, len);

  size_t i = 0;
  for (; i + 16 <= len; i += 16) {
    if (!neon_chunk_ascii_blank(ptr + i)) return false;
  }
  if (i == len) return true;

  return neon_chunk_ascii_blank(ptr + len - 16);
}
#endif

#if defined(SIN_FAST_BLANK_AVX2_DISPATCH)
typedef bool (*blank_check_func)(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos);
typedef bool (*ascii_blank_check_func)(const unsigned char* ptr, size_t len);

/* Written once by Init_sin_fast_blank before the methods become callable, read-only afterwards. */
static blank_check_func check_blank_dispatch = check_blank_sse2;
static ascii_blank_check_func check_ascii_blank_dispatch = check_ascii_blank_sse2;
#endif

/*
 * The len < 32 shortcut is check_blank_avx2's own first line, hoisted above the dispatch pointer. A call through a pointer cannot be
 * inlined, and an AVX2-target function cannot be inlined into this caller either, so without the hoist a short string pays two calls to
 * reach a scan the compiler would otherwise have inlined outright. The strings blank? is asked about are mostly short, and the condition
 * is the one check_blank_avx2 already tests, so nothing longer changes path.
 */
static inline bool check_blank(const unsigned char* ptr, size_t len, const unsigned char** non_ascii_pos) {
#if defined(SIN_FAST_BLANK_AVX2_DISPATCH)
  if (len < 32) return check_blank_sse2(ptr, len, non_ascii_pos);
  return check_blank_dispatch(ptr, len, non_ascii_pos);
#elif defined(SIN_FAST_BLANK_AVX2)
  return check_blank_avx2(ptr, len, non_ascii_pos);
#elif defined(SIN_FAST_BLANK_SSE2)
  return check_blank_sse2(ptr, len, non_ascii_pos);
#elif defined(SIN_FAST_BLANK_NEON)
  return check_blank_neon(ptr, len, non_ascii_pos);
#else
  return scan_ascii_blank(ptr, len, non_ascii_pos);
#endif
}

static inline bool check_ascii_blank(const unsigned char* ptr, size_t len) {
#if defined(SIN_FAST_BLANK_AVX2_DISPATCH)
  if (len < 32) return check_ascii_blank_sse2(ptr, len);
  return check_ascii_blank_dispatch(ptr, len);
#elif defined(SIN_FAST_BLANK_AVX2)
  return check_ascii_blank_avx2(ptr, len);
#elif defined(SIN_FAST_BLANK_SSE2)
  return check_ascii_blank_sse2(ptr, len);
#elif defined(SIN_FAST_BLANK_NEON)
  return check_ascii_blank_neon(ptr, len);
#else
  return scan_ascii_blank_or_null(ptr, len);
#endif
}

/*
 * Reached when the scanner cannot decode the bytes ahead. ActiveSupport's regexp never rescans: it trusts the code range Ruby cached on
 * the string, so it raises only for a string Ruby itself calls broken. Ruby's Big5-HKSCS, Big5-UAO, CP950 and CP951 transcoders emit
 * byte sequences their own scanner rejects while the code range still reads valid ('À'.encode('Big5-HKSCS')), and there ActiveSupport
 * answers "not blank" rather than raising. Reading the cached code range costs nothing; computing an uncomputed one would scan the
 * whole string, give up the early exit this loop exists for, and only ever come out broken anyway, since it runs the decode that just
 * failed here.
 */
static VALUE blank_undecodable(VALUE str, rb_encoding* enc) {
  if (ENC_CODERANGE(str) == ENC_CODERANGE_VALID) return Qfalse;
  rb_raise(rb_eArgError, "invalid byte sequence in %s", rb_enc_name(enc));
}

static VALUE rb_str_blank(VALUE str) {
  long len = RSTRING_LEN(str);
  if (len == 0) return Qtrue;

  const unsigned char* ptr = (const unsigned char*)RSTRING_PTR(str);
  const unsigned char* end = ptr + len;
  rb_encoding* enc = STR_ENC_GET(str);

  bool asciicompat = rb_enc_asciicompat(enc) != 0;
  if (asciicompat) {
    const unsigned char* non_ascii_pos = NULL;

    if (check_blank(ptr, (size_t)len, &non_ascii_pos)) return Qtrue;
    if (non_ascii_pos == NULL) return Qfalse;

    ptr = non_ascii_pos;
  }

  bool is_unicode = is_unicode_encoding(enc);
  while (ptr < end) {
    int clen = rb_enc_precise_mbclen((const char*)ptr, (const char*)end, enc);
    if (!MBCLEN_CHARFOUND_P(clen)) return blank_undecodable(str, enc);
    unsigned int codepoint = rb_enc_mbc_to_codepoint((const char*)ptr, (const char*)end, enc);
    if (!is_blank_codepoint(codepoint, enc, is_unicode)) return Qfalse;
    ptr += MBCLEN_CHARFOUND_LEN(clen);

    /*
     * An ASCII run starts here, so hand it back to the SIMD scan instead of decoding it a character at a time. Only an ASCII-compatible
     * encoding may do this: anywhere else a byte below 0x80 is not a character on its own.
     *
     * Resuming the decode afterwards is safe too. The scan only ever hands back a position holding a byte of 0x80 or above, and every
     * byte it passed was a single-byte blank, so the decode restarts on a character boundary. A non-blank ASCII byte settles the answer
     * outright and leaves no position to hand back.
     */
    if (asciicompat && ptr < end && *ptr < 0x80) {
      const unsigned char* non_ascii_pos = NULL;

      if (check_blank(ptr, (size_t)(end - ptr), &non_ascii_pos)) return Qtrue;
      if (non_ascii_pos == NULL) return Qfalse;

      ptr = non_ascii_pos;
    }
  }

  return Qtrue;
}

static VALUE rb_str_ascii_blank(VALUE str) {
  long len = RSTRING_LEN(str);
  if (len == 0) return Qtrue;

  const unsigned char* ptr = (const unsigned char*)RSTRING_PTR(str);
  const unsigned char* end = ptr + len;
  rb_encoding* enc = STR_ENC_GET(str);

  /*
   * This one never raises, because bytes that decode to nothing are no more an ASCII blank than the characters they failed to form.
   * An ASCII-compatible encoding does not even need the decoder: a byte of 0x80 or above only ever starts a character whose codepoint
   * is 0x80 or above there, so the first one settles the answer.
   */
  if (rb_enc_asciicompat(enc)) return check_ascii_blank(ptr, (size_t)len) ? Qtrue : Qfalse;

  while (ptr < end) {
    int clen = rb_enc_precise_mbclen((const char*)ptr, (const char*)end, enc);
    if (!MBCLEN_CHARFOUND_P(clen)) return Qfalse;
    unsigned int codepoint = rb_enc_mbc_to_codepoint((const char*)ptr, (const char*)end, enc);
    if (codepoint != 0 && !rb_isspace(codepoint)) return Qfalse;
    ptr += MBCLEN_CHARFOUND_LEN(clen);
  }

  return Qtrue;
}

void Init_sin_fast_blank(void) {
  /*
   * Declaring this is a promise, and what backs it is that both methods only ever read the string they are handed: the dispatch pointers
   * are written in this function and read everywhere else, and the code range is taken from the cache rather than computed, which would
   * write the result back onto the string. It has to run before the definitions, because what it marks is whatever is defined after it.
   */
#ifdef HAVE_RB_EXT_RACTOR_SAFE
  rb_ext_ractor_safe(true);
#endif

#if defined(SIN_FAST_BLANK_AVX2_DISPATCH)
  if (__builtin_cpu_supports("avx2")) {
    check_blank_dispatch = check_blank_avx2;
    check_ascii_blank_dispatch = check_ascii_blank_avx2;
  }
#endif

  rb_define_method(rb_cString, "blank?", rb_str_blank, 0);
  rb_define_method(rb_cString, "ascii_blank?", rb_str_ascii_blank, 0);
}
