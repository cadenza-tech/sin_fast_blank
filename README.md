# SinFastBlank

[![License](https://img.shields.io/github/license/cadenza-tech/sin_fast_blank?label=License&labelColor=343B42&color=blue)](https://github.com/cadenza-tech/sin_fast_blank/blob/main/LICENSE.txt) [![Tag](https://img.shields.io/github/tag/cadenza-tech/sin_fast_blank?label=Tag&logo=github&labelColor=343B42&color=2EBC4F)](https://github.com/cadenza-tech/sin_fast_blank/blob/main/CHANGELOG.md) [![Release](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/release.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Arelease) [![Test](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/test.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Atest) [![Lint](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/lint.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Alint)

Check for blank string faster than FastBlank and ActiveSupport.

Forked from [FastBlank](https://github.com/SamSaffron/fast_blank).

- [Installation](#installation)
- [Usage](#usage)
  - [String#blank?](#stringblank)
  - [String#ascii\_blank?](#stringascii_blank)
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

## Benchmark

SinFastBlank's String#blank? is about 1.3-9.3x faster than FastBlank's String#blank_as? and about 1.3-10.6x faster than ActiveSupport's String#blank?.

Additionally, this gem allocates no strings during the check, making it less of a burden on the GC.

```bash
$ bundle exec rake benchmark

+-------------------------------------------------------------------+
|                Benchmark Result (String Length: 0)                |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - ascii_blank? | 216909803.3          | -            |
| SinFastBlank - blank?       | 202197526.4          | -            |
| FastBlank - blank?          | 178264540.7          | 1.2x slower  |
| Scratch - blank_e?          | 172671205.3          | 1.3x slower  |
| ActiveSupport - blank?      | 172651770.0          | 1.3x slower  |
| Scratch - blank_f?          | 172629459.0          | 1.3x slower  |
| Scratch - blank_h?          | 172614624.6          | 1.3x slower  |
| Scratch - blank_g?          | 172611724.9          | 1.3x slower  |
| FastBlank - blank_as?       | 169349113.3          | 1.3x slower  |
| Scratch - blank_a?          | 24740328.0           | 8.8x slower  |
| Scratch - blank_c?          | 12168769.6           | 17.8x slower |
| Scratch - blank_b?          | 11989073.4           | 18.1x slower |
| Scratch - blank_d?          | 5196690.4            | 41.7x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|                Benchmark Result (String Length: 8)                |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - ascii_blank? | 98997203.5           | -            |
| SinFastBlank - blank?       | 96805819.9           | -            |
| FastBlank - blank?          | 32357130.6           | 3.1x slower  |
| FastBlank - blank_as?       | 29183259.2           | 3.4x slower  |
| Scratch - blank_c?          | 16111091.0           | 6.1x slower  |
| Scratch - blank_g?          | 15738316.1           | 6.3x slower  |
| ActiveSupport - blank?      | 15609713.7           | 6.3x slower  |
| Scratch - blank_f?          | 10848014.0           | 9.1x slower  |
| Scratch - blank_b?          | 10806036.7           | 9.2x slower  |
| Scratch - blank_a?          | 6284998.3            | 15.8x slower |
| Scratch - blank_e?          | 6232969.2            | 15.9x slower |
| Scratch - blank_d?          | 5827793.4            | 17.0x slower |
| Scratch - blank_h?          | 5811053.8            | 17.0x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|               Benchmark Result (String Length: 43)                |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - blank?       | 46414894.4           | -            |
| SinFastBlank - ascii_blank? | 40814946.0           | 1.1x slower  |
| FastBlank - blank_as?       | 4995669.3            | 9.3x slower  |
| Scratch - blank_b?          | 4832655.3            | 9.6x slower  |
| Scratch - blank_f?          | 4828479.7            | 9.6x slower  |
| FastBlank - blank?          | 4652567.6            | 10.0x slower |
| Scratch - blank_c?          | 4436042.8            | 10.5x slower |
| Scratch - blank_g?          | 4408696.6            | 10.5x slower |
| ActiveSupport - blank?      | 4381175.9            | 10.6x slower |
| Scratch - blank_d?          | 3609301.3            | 12.9x slower |
| Scratch - blank_h?          | 3593827.7            | 12.9x slower |
| Scratch - blank_a?          | 2266500.9            | 20.5x slower |
| Scratch - blank_e?          | 2260682.2            | 20.5x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|               Benchmark Result (String Length: 127)               |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - ascii_blank? | 120972640.9          | -            |
| SinFastBlank - blank?       | 112910414.3          | -            |
| FastBlank - blank?          | 49084147.2           | 2.5x slower  |
| FastBlank - blank_as?       | 46992403.2           | 2.6x slower  |
| Scratch - blank_c?          | 13700400.1           | 8.8x slower  |
| Scratch - blank_g?          | 13498822.8           | 9.0x slower  |
| ActiveSupport - blank?      | 13339587.2           | 9.1x slower  |
| Scratch - blank_a?          | 10576491.4           | 11.4x slower |
| Scratch - blank_e?          | 10417486.2           | 11.6x slower |
| Scratch - blank_d?          | 8033199.3            | 15.1x slower |
| Scratch - blank_h?          | 8032807.5            | 15.1x slower |
| Scratch - blank_b?          | 6015540.2            | 20.1x slower |
| Scratch - blank_f?          | 6004912.6            | 20.1x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|               Benchmark Result (String Length: 238)               |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - ascii_blank? | 120981124.5          | -            |
| SinFastBlank - blank?       | 112794703.3          | -            |
| FastBlank - blank?          | 48885194.0           | 2.5x slower  |
| FastBlank - blank_as?       | 46855937.6           | 2.6x slower  |
| Scratch - blank_c?          | 12194686.1           | 9.9x slower  |
| Scratch - blank_g?          | 11950420.6           | 10.1x slower |
| ActiveSupport - blank?      | 11848106.0           | 10.2x slower |
| Scratch - blank_a?          | 9188737.2            | 13.2x slower |
| Scratch - blank_e?          | 9099657.5            | 13.3x slower |
| Scratch - blank_d?          | 7442981.5            | 16.3x slower |
| Scratch - blank_h?          | 7422610.2            | 16.3x slower |
| Scratch - blank_b?          | 4197486.8            | 28.8x slower |
| Scratch - blank_f?          | 4176219.6            | 29.0x slower |
+-----------------------------+----------------------+--------------+
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
