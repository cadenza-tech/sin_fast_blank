# SinFastBlank

[![License](https://img.shields.io/github/license/cadenza-tech/sin_fast_blank?label=License&labelColor=343B42&color=blue)](https://github.com/cadenza-tech/sin_fast_blank/blob/main/LICENSE.txt) [![Tag](https://img.shields.io/github/tag/cadenza-tech/sin_fast_blank?label=Tag&logo=github&labelColor=343B42&color=2EBC4F)](https://github.com/cadenza-tech/sin_fast_blank/blob/main/CHANGELOG.md) [![Release](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/release.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Arelease) [![Test](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/test.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Atest) [![Lint](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/lint.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Alint)

Ruby extension library for up to 2x faster blank string checking than fast_blank gem.

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

SinFastBlank's String#blank_as? is about 1.0-2.2x faster than FastBlank's String#blank? and about 1.3-4.5x faster than ActiveSupport's String#blank?.

Additionally, this gem allocates no strings during the check, making it less of a burden on the GC.

```bash
$ bundle exec rake benchmark

+----------------------------------------------------------------+
|              Benchmark Result (String Length: 0)               |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank?    | 22966900.2           | -            |
| SinFastBlank - blank_as? | 22854446.4           | -            |
| FastBlank - blank_as?    | 22728273.3           | -            |
| FastBlank - blank?       | 22686375.5           | -            |
| Scratch - blank_e?       | 18352060.0           | 1.3x slower  |
| Scratch - blank_h?       | 18333765.0           | 1.3x slower  |
| ActiveSupport - blank?   | 18281624.8           | 1.3x slower  |
| Scratch - blank_f?       | 18275684.3           | 1.3x slower  |
| Scratch - blank_g?       | 18258123.1           | 1.3x slower  |
| Scratch - blank_a?       | 9898715.2            | 2.3x slower  |
| Scratch - blank_b?       | 4611313.1            | 5.0x slower  |
| Scratch - blank_c?       | 4596275.0            | 5.0x slower  |
| Scratch - blank_d?       | 1988432.0            | 11.6x slower |
+--------------------------+----------------------+--------------+

+----------------------------------------------------------------+
|              Benchmark Result (String Length: 8)               |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank_as? | 20957745.3           | -            |
| SinFastBlank - blank?    | 20490043.2           | -            |
| FastBlank - blank?       | 10437379.4           | 2.0x slower  |
| FastBlank - blank_as?    | 9600563.9            | 2.2x slower  |
| Scratch - blank_c?       | 7327192.6            | 2.9x slower  |
| ActiveSupport - blank?   | 5787065.3            | 3.6x slower  |
| Scratch - blank_g?       | 5773144.0            | 3.6x slower  |
| Scratch - blank_b?       | 4031677.5            | 5.2x slower  |
| Scratch - blank_f?       | 3570708.1            | 5.9x slower  |
| Scratch - blank_a?       | 3252559.0            | 6.4x slower  |
| Scratch - blank_e?       | 2915548.8            | 7.2x slower  |
| Scratch - blank_d?       | 2274928.0            | 9.2x slower  |
| Scratch - blank_h?       | 2090389.5            | 10.0x slower |
+--------------------------+----------------------+--------------+

+----------------------------------------------------------------+
|              Benchmark Result (String Length: 71)              |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank?    | 22707066.8           | -            |
| SinFastBlank - blank_as? | 21979788.3           | -            |
| FastBlank - blank?       | 21560180.9           | -            |
| FastBlank - blank_as?    | 21483377.6           | -            |
| Scratch - blank_a?       | 10495408.2           | 2.2x slower  |
| Scratch - blank_c?       | 8322278.6            | 2.7x slower  |
| Scratch - blank_e?       | 7454723.4            | 3.0x slower  |
| ActiveSupport - blank?   | 6519590.5            | 3.5x slower  |
| Scratch - blank_g?       | 6511631.5            | 3.5x slower  |
| Scratch - blank_d?       | 3984466.0            | 5.7x slower  |
| Scratch - blank_h?       | 3460504.5            | 6.6x slower  |
| Scratch - blank_b?       | 2260423.6            | 10.0x slower |
| Scratch - blank_f?       | 2043691.3            | 11.1x slower |
+--------------------------+----------------------+--------------+

+----------------------------------------------------------------+
|             Benchmark Result (String Length: 127)              |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank_as? | 21512568.0           | -            |
| SinFastBlank - blank?    | 21354195.5           | -            |
| FastBlank - blank?       | 14097188.9           | 1.5x slower  |
| FastBlank - blank_as?    | 13963065.1           | 1.5x slower  |
| Scratch - blank_c?       | 6460123.6            | 3.3x slower  |
| ActiveSupport - blank?   | 5304695.5            | 4.1x slower  |
| Scratch - blank_g?       | 5159539.0            | 4.2x slower  |
| Scratch - blank_a?       | 5106928.3            | 4.2x slower  |
| Scratch - blank_e?       | 4344099.2            | 5.0x slower  |
| Scratch - blank_d?       | 3516908.8            | 6.1x slower  |
| Scratch - blank_h?       | 3080467.6            | 7.0x slower  |
| Scratch - blank_b?       | 2380807.8            | 9.0x slower  |
| Scratch - blank_f?       | 2144800.2            | 10.0x slower |
+--------------------------+----------------------+--------------+

+----------------------------------------------------------------+
|             Benchmark Result (String Length: 238)              |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank_as? | 21539464.6           | -            |
| SinFastBlank - blank?    | 21428913.7           | -            |
| FastBlank - blank?       | 14208669.1           | 1.5x slower  |
| FastBlank - blank_as?    | 13947495.7           | 1.5x slower  |
| Scratch - blank_c?       | 5909689.1            | 3.6x slower  |
| ActiveSupport - blank?   | 4806411.1            | 4.5x slower  |
| Scratch - blank_g?       | 4644442.1            | 4.6x slower  |
| Scratch - blank_a?       | 4532311.2            | 4.8x slower  |
| Scratch - blank_e?       | 3788223.2            | 5.7x slower  |
| Scratch - blank_d?       | 3175205.6            | 6.8x slower  |
| Scratch - blank_h?       | 2800006.5            | 7.7x slower  |
| Scratch - blank_b?       | 1839252.0            | 11.7x slower |
| Scratch - blank_f?       | 1612757.1            | 13.4x slower |
+--------------------------+----------------------+--------------+
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

You can sponsor this project on [Patreon](https://patreon.com/CadenzaTech).
