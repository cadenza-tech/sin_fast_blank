# frozen_string_literal: true

require 'mkmf'

old_truffleruby = false
if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'truffleruby' && defined?(RUBY_ENGINE_VERSION)
  major_version = RUBY_ENGINE_VERSION.split('.').first.to_i
  old_truffleruby = major_version < 24
end

unless old_truffleruby
  case RbConfig::CONFIG['host_cpu']
  when /x86_64|i[3-6]86/
    $CFLAGS << ' -msse2'
    $CFLAGS << ' -mavx2' if have_header('immintrin.h') && try_compile('#include <immintrin.h>')
  when /aarch64|arm64/
    # No special flags needed as NEON is enabled by default on ARM64
  when /arm/
    $CFLAGS << ' -mfpu=neon' if have_header('arm_neon.h') && try_compile('#include <arm_neon.h>')
  end
end

$CFLAGS << ' -O3 -funroll-loops'

create_makefile 'sin_fast_blank'
