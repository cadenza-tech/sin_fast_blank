# SinFastBlank

[![License](https://img.shields.io/github/license/cadenza-tech/sin_fast_blank?label=License&labelColor=343B42&color=blue)](https://github.com/cadenza-tech/sin_fast_blank/blob/main/LICENSE.txt) [![Tag](https://img.shields.io/github/tag/cadenza-tech/sin_fast_blank?label=Tag&logo=github&labelColor=343B42&color=2EBC4F)](https://github.com/cadenza-tech/sin_fast_blank/blob/main/CHANGELOG.md) [![Release](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/release.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Arelease) [![Test](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/test.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Atest) [![Lint](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/lint.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Alint)

Ruby extension library for up to 3x faster blank string checking than fast_blank gem.

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

## Usage

### String#blank_as?

SinFastBlank's String#blank_as? is compatible with ActiveSupport's String#blank?.

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

### String#blank?

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

SinFastBlank's String#blank_as? is about 1.3-3.4x faster than FastBlank's String#blank_as? and about 1.3-10.3x faster than ActiveSupport's String#blank?.

Additionally, this gem allocates no strings during the check, making it less of a burden on the GC.

```bash
$ bundle exec rake benchmark

+----------------------------------------------------------------+
|              Benchmark Result (String Length: 0)               |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank?    | 220272628.9          | -            |
| SinFastBlank - blank_as? | 205391581.0          | -            |
| FastBlank - blank?       | 178296618.1          | 1.2x slower  |
| Scratch - blank_e?       | 172663191.8          | 1.3x slower  |
| Scratch - blank_f?       | 172662970.6          | 1.3x slower  |
| Scratch - blank_h?       | 172627104.3          | 1.3x slower  |
| ActiveSupport - blank?   | 172593842.6          | 1.3x slower  |
| Scratch - blank_g?       | 172504440.8          | 1.3x slower  |
| FastBlank - blank_as?    | 169299495.4          | 1.3x slower  |
| Scratch - blank_a?       | 24739741.9           | 8.9x slower  |
| Scratch - blank_c?       | 12145649.0           | 18.1x slower |
| Scratch - blank_b?       | 11728132.0           | 18.8x slower |
| Scratch - blank_d?       | 4758017.8            | 46.3x slower |
+--------------------------+----------------------+--------------+

+----------------------------------------------------------------+
|              Benchmark Result (String Length: 8)               |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank?    | 99316488.7           | -            |
| SinFastBlank - blank_as? | 95858683.3           | -            |
| FastBlank - blank?       | 31945152.5           | 3.1x slower  |
| FastBlank - blank_as?    | 29010959.4           | 3.4x slower  |
| Scratch - blank_c?       | 16121006.3           | 6.2x slower  |
| Scratch - blank_g?       | 15652169.3           | 6.3x slower  |
| ActiveSupport - blank?   | 15604810.7           | 6.4x slower  |
| Scratch - blank_b?       | 10805728.3           | 9.2x slower  |
| Scratch - blank_f?       | 10772269.2           | 9.2x slower  |
| Scratch - blank_a?       | 6286540.4            | 15.8x slower |
| Scratch - blank_e?       | 6237519.6            | 15.9x slower |
| Scratch - blank_d?       | 5259930.5            | 18.9x slower |
| Scratch - blank_h?       | 5244677.6            | 18.9x slower |
+--------------------------+----------------------+--------------+

+----------------------------------------------------------------+
|              Benchmark Result (String Length: 71)              |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank?    | 154030295.4          | -            |
| SinFastBlank - blank_as? | 135556798.4          | 1.1x slower  |
| FastBlank - blank?       | 113542533.8          | 1.4x slower  |
| FastBlank - blank_as?    | 105783463.7          | 1.5x slower  |
| Scratch - blank_a?       | 28002415.5           | 5.5x slower  |
| Scratch - blank_e?       | 26543347.8           | 5.8x slower  |
| Scratch - blank_c?       | 18993701.7           | 8.1x slower  |
| ActiveSupport - blank?   | 18277098.5           | 8.4x slower  |
| Scratch - blank_g?       | 18209533.8           | 8.5x slower  |
| Scratch - blank_d?       | 9407379.1            | 16.4x slower |
| Scratch - blank_h?       | 9384844.3            | 16.4x slower |
| Scratch - blank_b?       | 5025826.5            | 30.6x slower |
| Scratch - blank_f?       | 4920626.0            | 31.3x slower |
+--------------------------+----------------------+--------------+

+----------------------------------------------------------------+
|             Benchmark Result (String Length: 127)              |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank?    | 120816381.4          | -            |
| SinFastBlank - blank_as? | 112942015.6          | -            |
| FastBlank - blank?       | 49063027.7           | 2.5x slower  |
| FastBlank - blank_as?    | 46986294.5           | 2.6x slower  |
| Scratch - blank_c?       | 13643307.3           | 8.9x slower  |
| Scratch - blank_g?       | 13391399.1           | 9.0x slower  |
| ActiveSupport - blank?   | 13346991.2           | 9.1x slower  |
| Scratch - blank_a?       | 10550195.4           | 11.5x slower |
| Scratch - blank_e?       | 10383129.5           | 11.6x slower |
| Scratch - blank_d?       | 7901646.3            | 15.3x slower |
| Scratch - blank_h?       | 7871979.3            | 15.3x slower |
| Scratch - blank_f?       | 5386684.1            | 22.4x slower |
| Scratch - blank_b?       | 5305109.6            | 22.8x slower |
+--------------------------+----------------------+--------------+

+----------------------------------------------------------------+
|             Benchmark Result (String Length: 238)              |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank?    | 121015644.9          | -            |
| SinFastBlank - blank_as? | 112957090.8          | -            |
| FastBlank - blank?       | 49089308.3           | 2.5x slower  |
| FastBlank - blank_as?    | 47059926.1           | 2.6x slower  |
| Scratch - blank_c?       | 12089725.9           | 10.0x slower |
| Scratch - blank_g?       | 11864348.6           | 10.2x slower |
| ActiveSupport - blank?   | 11707898.8           | 10.3x slower |
| Scratch - blank_a?       | 9179575.9            | 13.2x slower |
| Scratch - blank_e?       | 9041236.4            | 13.4x slower |
| Scratch - blank_h?       | 7399548.4            | 16.4x slower |
| Scratch - blank_d?       | 7274842.9            | 16.6x slower |
| Scratch - blank_b?       | 3869438.0            | 31.3x slower |
| Scratch - blank_f?       | 3861215.8            | 31.3x slower |
+--------------------------+----------------------+--------------+
```

The benchmark was executed in the following environment:

`ruby 3.4.2 (2025-02-15 revision d2930f8e7a) +YJIT +PRISM [arm64-darwin24]`

Performance depends not only on the string length but also on its content.

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
