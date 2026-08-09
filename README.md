# SinFastBlank

[![License](https://img.shields.io/github/license/cadenza-tech/sin_fast_blank?label=License&labelColor=343B42&color=blue)](https://github.com/cadenza-tech/sin_fast_blank/blob/main/LICENSE.txt) [![Tag](https://img.shields.io/github/tag/cadenza-tech/sin_fast_blank?label=Tag&logo=github&labelColor=343B42&color=2EBC4F)](https://github.com/cadenza-tech/sin_fast_blank/blob/main/CHANGELOG.md) [![Release](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/release.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Arelease) [![Test](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/test.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Atest) [![Lint](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/lint.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Alint)

Check for blank string faster than FastBlank or ActiveSupport.

Forked from [FastBlank](https://github.com/SamSaffron/fast_blank).

- [Installation](#installation)
- [Usage](#usage)
  - [String#blank?](#stringblank)
  - [String#ascii\_blank?](#stringascii_blank)
- [Benchmark](#benchmark)
- [Development](#development)
  - [Building for JRuby](#building-for-jruby)
- [Changelog](#changelog)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)
- [Sponsor](#sponsor)

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add sin_fast_blank
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install sin_fast_blank
```

## Usage

Both methods can be called inside non-main Ractors on CRuby 3.0+.

ActiveSupport defines `String#blank?` on String itself in every version, so whichever of the two is loaded last replaces the other: require `sin_fast_blank` after ActiveSupport. `require 'active_support'` on its own does not reach that definition, while `active_support/all`, `active_support/core_ext/object`, `active_support/core_ext/object/blank` and `rails/all` do. `String.instance_method(:blank?).source_location` is `nil` while the extension is the one in place. `String#ascii_blank?` has no ActiveSupport counterpart and is never replaced.

### String#blank?

SinFastBlank's String#blank? is compatible with ActiveSupport's String#blank?.

```ruby
require 'sin_fast_blank'

''.blank? # => true
' '.blank? # => true
'　'.blank? # => true
"\t".blank? # => true
"\r".blank? # => true
"\n".blank? # => true
"\r\n".blank? # => true
"\r\n\v\f\r\s\t".blank? # => true
'abc'.blank? # => false
' abc '.blank? # => false
```

The check is encoding-aware: codepoints match the same per-encoding `[[:space:]]` tables that ActiveSupport's regexp uses. This holds on CRuby and JRuby. TruffleRuby's regexp engine consults a different table, so a handful of single-byte cases disagree: it reports `0x85` and `0xA0` as blank in encodings whose ctype table does not, such as `ASCII-8BIT`.

Dummy encodings are the one place the two part ways. ActiveSupport cannot build its regexp for a string tagged `ISO-2022-JP`, `UTF-16` or `UTF-7`, so it raises `RegexpError` or `Encoding::ConverterNotFoundError`; `String#blank?` scans the bytes and answers.

SinFastBlank scans left to right and returns as soon as the result is decided, so it can answer before reaching an invalid byte sequence that ActiveSupport's whole-string regexp would trip over: `"a\xFF".blank?` returns `false` where ActiveSupport raises `ArgumentError`. Once the scan does reach one, `blank?` matches ActiveSupport exactly: it raises `ArgumentError` for a string Ruby itself calls broken, and answers `false` for one whose bytes Ruby's own transcoder produced but its scanner rejects (`'À'.encode('Big5-HKSCS')`), which ActiveSupport does not treat as an error either.

One more case parts ways, this time on the receiver rather than its bytes: ActiveSupport shortcuts on `empty?` before matching its regexp, so a String that overrides `empty?` to return true is blank there, where `String#blank?` reads the bytes and answers on what they hold. ActiveSupport documents that call as a speedup for empty strings rather than a hook, and `ActiveSupport::SafeBuffer` does not override it.

### String#ascii_blank?

```ruby
require 'sin_fast_blank'

''.ascii_blank? # => true
' '.ascii_blank? # => true
"\t".ascii_blank? # => true
"\r".ascii_blank? # => true
"\n".ascii_blank? # => true
"\r\n".ascii_blank? # => true
"\r\n\v\f\r\s\t".ascii_blank? # => true
'abc'.ascii_blank? # => false
' abc '.ascii_blank? # => false
```

Only ASCII whitespace counts, so `String#ascii_blank?` never raises: bytes that form no character are not ASCII whitespace either, and `"\xFF".ascii_blank?` simply returns `false`.

## Benchmark

SinFastBlank's String#blank? is about 1.3-16.3x faster than FastBlank's String#blank_as? and about 1.2-23.0x faster than ActiveSupport's String#blank?. SinFastBlank's String#ascii_blank? is about 1.2-23.2x faster than FastBlank's String#blank?. At string length 123 the measurement does not separate String#blank? from FastBlank's String#blank_as?, so both are reported as Fastest there.

Additionally, this gem allocates no strings during the check, making it less of a burden on the GC.

Each string length is reported as two tables because the groups answer different questions: the ActiveSupport-compatible group calls U+3000 and U+00A0 blank, while the ASCII-only pair returns false for both. Ranking them together would compare methods that never did the same work.

```bash
$ bundle exec rake benchmark
Benchmarking string length: 0...
Benchmarking string length: 8...
Benchmarking string length: 43...
Benchmarking string length: 123...
Benchmarking string length: 127...
Benchmarking string length: 238...

+-----------------------------------------------------------------------+
|     Benchmark Result (String Length: 0, ActiveSupport-compatible)     |
+------------------------+----------------------+--------+--------------+
| Name                   | Iteration Per Second | Error  | Speed Ratio  |
+------------------------+----------------------+--------+--------------+
| SinFastBlank - blank?  | 189268656.7          | ±0.48% | Fastest      |
| Scratch - blank_e?     | 159245632.6          | ±0.42% | 1.2x slower  |
| Scratch - blank_g?     | 159177797.8          | ±0.51% | 1.2x slower  |
| ActiveSupport - blank? | 159005067.3          | ±1.02% | 1.2x slower  |
| Scratch - blank_f?     | 158579113.9          | ±1.72% | 1.2x slower  |
| Scratch - blank_h?     | 158312815.2          | ±0.38% | 1.2x slower  |
| FastBlank - blank_as?  | 146149656.1          | ±2.58% | 1.3x slower  |
| Scratch - blank_a?     | 24506273.5           | ±0.37% | 7.7x slower  |
| Scratch - blank_c?     | 11745600.3           | ±0.23% | 16.1x slower |
| Scratch - blank_b?     | 10570972.1           | ±0.56% | 17.9x slower |
| Scratch - blank_d?     | 4905509.6            | ±0.33% | 38.6x slower |
+------------------------+----------------------+--------+--------------+

+---------------------------------------------------------------------------+
|              Benchmark Result (String Length: 0, ASCII-only)              |
+-----------------------------+----------------------+--------+-------------+
| Name                        | Iteration Per Second | Error  | Speed Ratio |
+-----------------------------+----------------------+--------+-------------+
| SinFastBlank - ascii_blank? | 203193300.1          | ±1.09% | Fastest     |
| FastBlank - blank?          | 147055633.6          | ±0.60% | 1.4x slower |
+-----------------------------+----------------------+--------+-------------+

+-----------------------------------------------------------------------+
|     Benchmark Result (String Length: 8, ActiveSupport-compatible)     |
+------------------------+----------------------+--------+--------------+
| Name                   | Iteration Per Second | Error  | Speed Ratio  |
+------------------------+----------------------+--------+--------------+
| SinFastBlank - blank?  | 77064598.2           | ±0.31% | Fastest      |
| FastBlank - blank_as?  | 27870007.6           | ±0.62% | 2.8x slower  |
| Scratch - blank_c?     | 14118003.3           | ±0.26% | 5.5x slower  |
| ActiveSupport - blank? | 13698901.0           | ±0.52% | 5.6x slower  |
| Scratch - blank_g?     | 13635284.9           | ±0.20% | 5.7x slower  |
| Scratch - blank_b?     | 10198011.1           | ±2.15% | 7.6x slower  |
| Scratch - blank_f?     | 10142164.2           | ±0.32% | 7.6x slower  |
| Scratch - blank_a?     | 6783807.1            | ±0.98% | 11.4x slower |
| Scratch - blank_e?     | 6521011.0            | ±0.29% | 11.8x slower |
| Scratch - blank_d?     | 5215856.9            | ±1.46% | 14.8x slower |
| Scratch - blank_h?     | 5166323.2            | ±1.75% | 14.9x slower |
+------------------------+----------------------+--------+--------------+

+---------------------------------------------------------------------------+
|              Benchmark Result (String Length: 8, ASCII-only)              |
+-----------------------------+----------------------+--------+-------------+
| Name                        | Iteration Per Second | Error  | Speed Ratio |
+-----------------------------+----------------------+--------+-------------+
| SinFastBlank - ascii_blank? | 89085855.6           | ±0.19% | Fastest     |
| FastBlank - blank?          | 31180410.5           | ±0.32% | 2.9x slower |
+-----------------------------+----------------------+--------+-------------+

+-----------------------------------------------------------------------+
|    Benchmark Result (String Length: 43, ActiveSupport-compatible)     |
+------------------------+----------------------+--------+--------------+
| Name                   | Iteration Per Second | Error  | Speed Ratio  |
+------------------------+----------------------+--------+--------------+
| SinFastBlank - blank?  | 80570773.4           | ±0.17% | Fastest      |
| FastBlank - blank_as?  | 4951349.2            | ±0.21% | 16.3x slower |
| Scratch - blank_b?     | 4572305.5            | ±1.00% | 17.6x slower |
| Scratch - blank_f?     | 4437925.4            | ±1.15% | 18.2x slower |
| Scratch - blank_g?     | 3531002.2            | ±0.84% | 22.8x slower |
| Scratch - blank_c?     | 3523113.8            | ±1.96% | 22.9x slower |
| ActiveSupport - blank? | 3510419.5            | ±2.05% | 23.0x slower |
| Scratch - blank_h?     | 2976077.1            | ±0.52% | 27.1x slower |
| Scratch - blank_d?     | 2922150.2            | ±2.47% | 27.6x slower |
| Scratch - blank_a?     | 2275385.3            | ±1.61% | 35.4x slower |
| Scratch - blank_e?     | 2257794.6            | ±1.32% | 35.7x slower |
+------------------------+----------------------+--------+--------------+

+----------------------------------------------------------------------------+
|              Benchmark Result (String Length: 43, ASCII-only)              |
+-----------------------------+----------------------+--------+--------------+
| Name                        | Iteration Per Second | Error  | Speed Ratio  |
+-----------------------------+----------------------+--------+--------------+
| SinFastBlank - ascii_blank? | 105229741.2          | ±0.55% | Fastest      |
| FastBlank - blank?          | 4543568.4            | ±3.49% | 23.2x slower |
+-----------------------------+----------------------+--------+--------------+

+-----------------------------------------------------------------------+
|    Benchmark Result (String Length: 123, ActiveSupport-compatible)    |
+------------------------+----------------------+--------+--------------+
| Name                   | Iteration Per Second | Error  | Speed Ratio  |
+------------------------+----------------------+--------+--------------+
| SinFastBlank - blank?  | 96936949.7           | ±3.02% | Fastest      |
| FastBlank - blank_as?  | 93386361.9           | ±0.75% | Fastest      |
| Scratch - blank_a?     | 26971080.4           | ±2.73% | 3.6x slower  |
| Scratch - blank_e?     | 25639570.3           | ±0.18% | 3.8x slower  |
| Scratch - blank_c?     | 18687829.5           | ±0.25% | 5.2x slower  |
| Scratch - blank_g?     | 17894413.2           | ±0.33% | 5.4x slower  |
| ActiveSupport - blank? | 16714938.4           | ±4.62% | 5.8x slower  |
| Scratch - blank_d?     | 9048125.6            | ±0.37% | 10.7x slower |
| Scratch - blank_h?     | 8987475.0            | ±0.68% | 10.8x slower |
| Scratch - blank_b?     | 5352834.6            | ±0.37% | 18.1x slower |
| Scratch - blank_f?     | 5191973.0            | ±0.67% | 18.7x slower |
+------------------------+----------------------+--------+--------------+

+---------------------------------------------------------------------------+
|             Benchmark Result (String Length: 123, ASCII-only)             |
+-----------------------------+----------------------+--------+-------------+
| Name                        | Iteration Per Second | Error  | Speed Ratio |
+-----------------------------+----------------------+--------+-------------+
| SinFastBlank - ascii_blank? | 120606725.9          | ±0.94% | Fastest     |
| FastBlank - blank?          | 102556412.3          | ±0.20% | 1.2x slower |
+-----------------------------+----------------------+--------+-------------+

+-----------------------------------------------------------------------+
|    Benchmark Result (String Length: 127, ActiveSupport-compatible)    |
+------------------------+----------------------+--------+--------------+
| Name                   | Iteration Per Second | Error  | Speed Ratio  |
+------------------------+----------------------+--------+--------------+
| SinFastBlank - blank?  | 80551912.4           | ±0.35% | Fastest      |
| FastBlank - blank_as?  | 42206464.1           | ±0.96% | 1.9x slower  |
| Scratch - blank_c?     | 12828245.1           | ±0.23% | 6.3x slower  |
| ActiveSupport - blank? | 12485897.9           | ±0.52% | 6.5x slower  |
| Scratch - blank_g?     | 12442303.6           | ±0.23% | 6.5x slower  |
| Scratch - blank_a?     | 10419013.7           | ±0.16% | 7.7x slower  |
| Scratch - blank_e?     | 10168685.4           | ±0.27% | 7.9x slower  |
| Scratch - blank_d?     | 7442964.2            | ±0.58% | 10.8x slower |
| Scratch - blank_h?     | 7397822.4            | ±0.27% | 10.9x slower |
| Scratch - blank_b?     | 5286423.4            | ±0.33% | 15.2x slower |
| Scratch - blank_f?     | 5207047.6            | ±0.39% | 15.5x slower |
+------------------------+----------------------+--------+--------------+

+---------------------------------------------------------------------------+
|             Benchmark Result (String Length: 127, ASCII-only)             |
+-----------------------------+----------------------+--------+-------------+
| Name                        | Iteration Per Second | Error  | Speed Ratio |
+-----------------------------+----------------------+--------+-------------+
| SinFastBlank - ascii_blank? | 120881119.0          | ±0.24% | Fastest     |
| FastBlank - blank?          | 45716325.1           | ±0.32% | 2.6x slower |
+-----------------------------+----------------------+--------+-------------+

+-----------------------------------------------------------------------+
|    Benchmark Result (String Length: 238, ActiveSupport-compatible)    |
+------------------------+----------------------+--------+--------------+
| Name                   | Iteration Per Second | Error  | Speed Ratio  |
+------------------------+----------------------+--------+--------------+
| SinFastBlank - blank?  | 80596263.4           | ±0.20% | Fastest      |
| FastBlank - blank_as?  | 42305937.1           | ±0.20% | 1.9x slower  |
| Scratch - blank_c?     | 11596439.7           | ±0.33% | 7.0x slower  |
| ActiveSupport - blank? | 11307320.4           | ±0.51% | 7.1x slower  |
| Scratch - blank_g?     | 11288221.5           | ±0.24% | 7.1x slower  |
| Scratch - blank_a?     | 9202475.9            | ±0.26% | 8.8x slower  |
| Scratch - blank_e?     | 9013830.2            | ±0.28% | 8.9x slower  |
| Scratch - blank_d?     | 7162431.6            | ±0.57% | 11.3x slower |
| Scratch - blank_h?     | 7119191.1            | ±1.11% | 11.3x slower |
| Scratch - blank_b?     | 3924922.1            | ±0.78% | 20.5x slower |
| Scratch - blank_f?     | 3859441.2            | ±0.38% | 20.9x slower |
+------------------------+----------------------+--------+--------------+

+---------------------------------------------------------------------------+
|             Benchmark Result (String Length: 238, ASCII-only)             |
+-----------------------------+----------------------+--------+-------------+
| Name                        | Iteration Per Second | Error  | Speed Ratio |
+-----------------------------+----------------------+--------+-------------+
| SinFastBlank - ascii_blank? | 120877343.1          | ±0.18% | Fastest     |
| FastBlank - blank?          | 45726024.3           | ±0.20% | 2.6x slower |
+-----------------------------+----------------------+--------+-------------+
```

Each row's error is how much its own measurement moved within that run. Across runs the whole machine drifts further than that, so the ratios above move by a few tenths from one run to the next.

The error is also what decides the Speed Ratio column: a row is labelled Fastest when its gap to the top row is narrower than the two errors together, because a gap that small is the measurement failing to separate them rather than a difference it found. More than one row can therefore read Fastest.

Performance depends not only on the string length but also on its content.

The benchmark was executed in the following environment:

- Ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +YJIT +PRISM [arm64-darwin25]
- FastBlank 1.0.1
- ActiveSupport 8.1.3.1

## Development

### Building for JRuby

To build the Java extension and run tests for JRuby support:

```bash
./script/jruby_build_and_test.sh
```

## Changelog

See [CHANGELOG.md](https://github.com/cadenza-tech/sin_fast_blank/blob/main/CHANGELOG.md).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cadenza-tech/sin_fast_blank. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cadenza-tech/sin_fast_blank/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/cadenza-tech/sin_fast_blank/blob/main/LICENSE.txt).

## Code of Conduct

Everyone interacting in the SinFastBlank project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cadenza-tech/sin_fast_blank/blob/main/CODE_OF_CONDUCT.md).

## Sponsor

You can sponsor this project on [GitHub Sponsors](https://github.com/sponsors/cadenza-tech).
