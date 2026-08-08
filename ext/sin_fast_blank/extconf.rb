# frozen_string_literal: true

require 'mkmf'

# Compile-wide -mavx2 bakes AVX2 into the binary and crashes with SIGILL on CPUs without it
# (pre-Haswell, QEMU defaults, some VPS), so probe for per-function AVX2 + runtime detection and let
# Init_sin_fast_blank choose. try_link, not try_compile: __builtin_cpu_supports needs link-time runtime support.
AVX2_RUNTIME_DISPATCH_PROBE = <<~SRC
  #include <immintrin.h>
  __attribute__((target("avx2"))) static int avx2_probe(void) {
    __m256i zero = _mm256_setzero_si256();
    return _mm256_movemask_epi8(_mm256_cmpeq_epi8(zero, zero));
  }
  int main(void) {
    return __builtin_cpu_supports("avx2") ? avx2_probe() : 0;
  }
SRC

old_truffleruby = false
if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'truffleruby' && defined?(RUBY_ENGINE_VERSION)
  major_version = RUBY_ENGINE_VERSION.split('.').first.to_i
  old_truffleruby = major_version < 24
end

unless old_truffleruby
  case RbConfig::CONFIG['host_cpu']
  when /x86_64|i[3-6]86/
    # SSE2 is part of the x86_64 ABI, so -msse2 is always safe there. On 32-bit x86 it is
    # still compiled in unconditionally (pre-SSE2 CPUs would need a runtime dispatch as well).
    # append_cflags, not $CFLAGS <<: MSVC does not know the flag and would only warn about it,
    # and it does not need it either, since sin_fast_blank.c reads _M_X64 to reach the same conclusion.
    append_cflags('-msse2')
    $CFLAGS << ' -DHAVE_AVX2_RUNTIME_DISPATCH' if checking_for('AVX2 runtime dispatch') { try_link(AVX2_RUNTIME_DISPATCH_PROBE) }
  when /aarch64|arm64/
    # No special flags needed as NEON is enabled by default on ARM64
  when /arm/
    $CFLAGS << ' -mfpu=neon' if have_header('arm_neon.h') && try_compile('#include <arm_neon.h>')
  end
end

# rb_ext_ractor_safe() arrived in Ruby 3.0 and the gem still supports 2.3, so Init_sin_fast_blank guards its call on this.
have_func('rb_ext_ractor_safe')

# Both are GCC/Clang spellings. MSVC ignores them with a warning and keeps the /O2 Ruby already passes.
append_cflags(['-O3', '-funroll-loops'])

create_makefile 'sin_fast_blank/sin_fast_blank'
