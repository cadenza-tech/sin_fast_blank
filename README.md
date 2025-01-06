# SinFastBlank

[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/cadenza-tech/sin_fast_blank/blob/main/LICENSE.txt) [![tag](https://img.shields.io/github/tag/cadenza-tech/sin_fast_blank.svg?logo=github&color=2EBC4F)](https://github.com/cadenza-tech/sin_fast_blank/blob/main/CHANGELOG.md) [![release](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/release.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Arelease) [![test](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/test.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Atest) [![lint](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/lint.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Alint)

Ruby extension library for fast blank string checking.

Forked from [FastBlank](https://github.com/SamSaffron/fast_blank).

- [Installation](#installation)
- [Usage](#usage)
  - [String#blank\_as?](#stringblank_as)
  - [String#blank?](#stringblank)
- [Benchmark](#benchmark)
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

# Usage

## String#blank_as?

FastBlank's String#blank_as? is compatible with ActiveSupport's String#blank?.

```ruby
require 'sin_fast_blank'

''.blank_as? # => true
' '.blank_as? # => true
'　'.blank_as? # => true
"\t".blank_as? # => true
"\r".blank_as? # => true
"\n".blank_as? # => true
"\r\n".blank_as? # => true
"\r\n\v\f\r\s\t".blank_as? # => true
'abc'.blank_as? # => false
' abc '.blank_as? # => false
```

## String#blank?

```ruby
require 'sin_fast_blank'

''.blank? # => true
' '.blank? # => true
"\t".blank? # => true
"\r".blank? # => true
"\n".blank? # => true
"\r\n".blank? # => true
"\r\n\v\f\r\s\t".blank? # => true
'abc'.blank? # => false
' abc '.blank? # => false
```

## Benchmark

FastBlank's String#blank_as? is about 1.2-3.3x faster than ActiveSupport's String#blank? with Ruby 3.4 on Apple Silicon Mac.

```bash
$ bundle exec rake benchmark

======================== Benchmark String Length: 0 ========================
Warming up --------------------------------------
 FastBlank-blank_as?     3.875M i/100ms
    FastBlank-blank?     3.157M i/100ms
ActiveSupport-blank?     3.156M i/100ms
    Scratch-blank_a?   327.875k i/100ms
    Scratch-blank_b?     3.157M i/100ms
Calculating -------------------------------------
 FastBlank-blank_as?     39.521M (± 0.7%) i/s   (25.30 ns/i) -    197.604M in   5.000221s
    FastBlank-blank?     31.564M (± 0.5%) i/s   (31.68 ns/i) -    157.863M in   5.001518s
ActiveSupport-blank?     31.500M (± 1.1%) i/s   (31.75 ns/i) -    157.820M in   5.010796s
    Scratch-blank_a?      3.202M (± 2.2%) i/s  (312.33 ns/i) -     16.066M in   5.020372s
    Scratch-blank_b?     31.553M (± 0.6%) i/s   (31.69 ns/i) -    157.835M in   5.002410s

Comparison:
 FastBlank-blank_as?: 39521076.3 i/s
    FastBlank-blank?: 31564043.8 i/s - 1.25x  slower
    Scratch-blank_b?: 31552753.4 i/s - 1.25x  slower
ActiveSupport-blank?: 31500130.6 i/s - 1.25x  slower
    Scratch-blank_a?:  3201765.5 i/s - 12.34x  slower


======================== Benchmark String Length: 8 ========================
Warming up --------------------------------------
 FastBlank-blank_as?     1.722M i/100ms
    FastBlank-blank?     1.000M i/100ms
ActiveSupport-blank?   999.986k i/100ms
    Scratch-blank_a?   378.121k i/100ms
    Scratch-blank_b?   609.164k i/100ms
Calculating -------------------------------------
 FastBlank-blank_as?     17.203M (± 0.4%) i/s   (58.13 ns/i) -     86.110M in   5.005514s
    FastBlank-blank?      9.979M (± 0.7%) i/s  (100.21 ns/i) -     50.022M in   5.012826s
ActiveSupport-blank?      9.974M (± 1.2%) i/s  (100.26 ns/i) -     49.999M in   5.013807s
    Scratch-blank_a?      3.835M (± 1.5%) i/s  (260.73 ns/i) -     19.284M in   5.029084s
    Scratch-blank_b?      6.012M (± 3.2%) i/s  (166.34 ns/i) -     30.458M in   5.071787s

Comparison:
 FastBlank-blank_as?: 17203216.7 i/s
    FastBlank-blank?:  9979246.8 i/s - 1.72x  slower
ActiveSupport-blank?:  9973883.6 i/s - 1.72x  slower
    Scratch-blank_b?:  6011697.6 i/s - 2.86x  slower
    Scratch-blank_a?:  3835344.6 i/s - 4.49x  slower


======================== Benchmark String Length: 11 ========================
Warming up --------------------------------------
 FastBlank-blank_as?     3.669M i/100ms
    FastBlank-blank?     1.139M i/100ms
ActiveSupport-blank?     1.139M i/100ms
    Scratch-blank_a?   676.009k i/100ms
    Scratch-blank_b?   331.040k i/100ms
Calculating -------------------------------------
 FastBlank-blank_as?     36.983M (± 0.5%) i/s   (27.04 ns/i) -    187.122M in   5.059876s
    FastBlank-blank?     11.255M (± 4.8%) i/s   (88.85 ns/i) -     56.932M in   5.075337s
ActiveSupport-blank?     11.295M (± 1.0%) i/s   (88.54 ns/i) -     56.926M in   5.040663s
    Scratch-blank_a?      6.596M (± 3.0%) i/s  (151.61 ns/i) -     33.124M in   5.026658s
    Scratch-blank_b?      3.323M (± 1.7%) i/s  (300.91 ns/i) -     16.883M in   5.081642s

Comparison:
 FastBlank-blank_as?: 36982589.0 i/s
ActiveSupport-blank?: 11294533.9 i/s - 3.27x  slower
    FastBlank-blank?: 11254762.4 i/s - 3.29x  slower
    Scratch-blank_a?:  6595961.9 i/s - 5.61x  slower
    Scratch-blank_b?:  3323306.3 i/s - 11.13x  slower


======================== Benchmark String Length: 15 ========================
Warming up --------------------------------------
 FastBlank-blank_as?     2.363M i/100ms
    FastBlank-blank?   916.697k i/100ms
ActiveSupport-blank?   912.457k i/100ms
    Scratch-blank_a?   589.180k i/100ms
    Scratch-blank_b?   350.303k i/100ms
Calculating -------------------------------------
 FastBlank-blank_as?     23.967M (± 0.7%) i/s   (41.72 ns/i) -    120.525M in   5.029052s
    FastBlank-blank?      9.123M (± 1.0%) i/s  (109.61 ns/i) -     45.835M in   5.024689s
ActiveSupport-blank?      9.075M (± 0.8%) i/s  (110.20 ns/i) -     45.623M in   5.027882s
    Scratch-blank_a?      5.855M (± 1.9%) i/s  (170.78 ns/i) -     29.459M in   5.032877s
    Scratch-blank_b?      3.462M (± 1.6%) i/s  (288.89 ns/i) -     17.515M in   5.061190s

Comparison:
 FastBlank-blank_as?: 23966769.3 i/s
    FastBlank-blank?:  9122861.7 i/s - 2.63x  slower
ActiveSupport-blank?:  9074573.7 i/s - 2.64x  slower
    Scratch-blank_a?:  5855362.3 i/s - 4.09x  slower
    Scratch-blank_b?:  3461525.5 i/s - 6.92x  slower


======================== Benchmark String Length: 127 ========================
Warming up --------------------------------------
 FastBlank-blank_as?     2.371M i/100ms
    FastBlank-blank?   917.465k i/100ms
ActiveSupport-blank?   917.407k i/100ms
    Scratch-blank_a?   595.119k i/100ms
    Scratch-blank_b?   349.548k i/100ms
Calculating -------------------------------------
 FastBlank-blank_as?     24.013M (± 0.6%) i/s   (41.64 ns/i) -    120.900M in   5.034924s
    FastBlank-blank?      9.156M (± 0.7%) i/s  (109.22 ns/i) -     45.873M in   5.010639s
ActiveSupport-blank?      9.127M (± 1.6%) i/s  (109.57 ns/i) -     45.870M in   5.027384s
    Scratch-blank_a?      5.823M (± 2.3%) i/s  (171.74 ns/i) -     29.161M in   5.010703s
    Scratch-blank_b?      3.491M (± 5.6%) i/s  (286.46 ns/i) -     17.477M in   5.027516s

Comparison:
 FastBlank-blank_as?: 24013203.9 i/s
    FastBlank-blank?:  9155676.4 i/s - 2.62x  slower
ActiveSupport-blank?:  9126665.5 i/s - 2.63x  slower
    Scratch-blank_a?:  5822794.3 i/s - 4.12x  slower
    Scratch-blank_b?:  3490840.0 i/s - 6.88x  slower
```

Additionally, this gem allocates no strings during the test, making it less of a GC burden.

## Changelog

See [CHANGELOG.md](https://github.com/cadenza-tech/sin_fast_blank/blob/main/CHANGELOG.md).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cadenza-tech/sin_fast_blank. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cadenza-tech/sin_fast_blank/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/cadenza-tech/sin_fast_blank/blob/main/LICENSE.txt).

## Code of Conduct

Everyone interacting in the SinFastBlank project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cadenza-tech/sin_fast_blank/blob/main/CODE_OF_CONDUCT.md).

## Sponsor

You can sponsor this project on [Patreon](https://patreon.com/CadenzaTech).
