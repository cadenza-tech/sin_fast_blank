# SinFastBlank

[![License](https://img.shields.io/github/license/cadenza-tech/sin_fast_blank?label=License&labelColor=343B42&color=blue)](https://github.com/cadenza-tech/sin_fast_blank/blob/main/LICENSE.txt) [![Tag](https://img.shields.io/github/tag/cadenza-tech/sin_fast_blank?label=Tag&logo=github&labelColor=343B42&color=2EBC4F)](https://github.com/cadenza-tech/sin_fast_blank/blob/main/CHANGELOG.md) [![Release](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/release.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Arelease) [![Test](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/test.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Atest) [![Lint](https://github.com/cadenza-tech/sin_fast_blank/actions/workflows/lint.yml/badge.svg)](https://github.com/cadenza-tech/sin_fast_blank/actions?query=workflow%3Alint)

Ruby extension library for up to 9x faster blank string checking than fast_blank gem.

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

SinFastBlank's String#blank_as? is about 1.3-9.3x faster than FastBlank's String#blank_as? and about 1.3-10.6x faster than ActiveSupport's String#blank?.

Additionally, this gem allocates no strings during the check, making it less of a burden on the GC.

```bash
$ bundle exec rake benchmark

+----------------------------------------------------------------+
|              Benchmark Result (String Length: 0)               |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank?    | 220329897.3          | -            |
| SinFastBlank - blank_as? | 205312772.2          | -            |
| FastBlank - blank?       | 178298823.4          | 1.2x slower  |
| Scratch - blank_e?       | 172623095.9          | 1.3x slower  |
| Scratch - blank_f?       | 172606768.7          | 1.3x slower  |
| Scratch - blank_g?       | 172602527.7          | 1.3x slower  |
| Scratch - blank_h?       | 172442054.2          | 1.3x slower  |
| ActiveSupport - blank?   | 172426162.4          | 1.3x slower  |
| FastBlank - blank_as?    | 169392392.9          | 1.3x slower  |
| Scratch - blank_a?       | 24736951.1           | 8.9x slower  |
| Scratch - blank_b?       | 12313448.2           | 17.9x slower |
| Scratch - blank_c?       | 12144356.7           | 18.1x slower |
| Scratch - blank_d?       | 5177260.5            | 42.6x slower |
+--------------------------+----------------------+--------------+

+----------------------------------------------------------------+
|              Benchmark Result (String Length: 8)               |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank?    | 99183763.3           | -            |
| SinFastBlank - blank_as? | 96790002.9           | -            |
| FastBlank - blank?       | 32373268.0           | 3.1x slower  |
| FastBlank - blank_as?    | 29230445.6           | 3.4x slower  |
| Scratch - blank_c?       | 16135257.4           | 6.1x slower  |
| Scratch - blank_g?       | 15754008.4           | 6.3x slower  |
| ActiveSupport - blank?   | 15547774.1           | 6.4x slower  |
| Scratch - blank_b?       | 10825108.5           | 9.2x slower  |
| Scratch - blank_f?       | 10792957.7           | 9.2x slower  |
| Scratch - blank_a?       | 6242357.5            | 15.9x slower |
| Scratch - blank_e?       | 6234070.0            | 15.9x slower |
| Scratch - blank_d?       | 5827164.1            | 17.0x slower |
| Scratch - blank_h?       | 5813357.7            | 17.1x slower |
+--------------------------+----------------------+--------------+

+----------------------------------------------------------------+
|              Benchmark Result (String Length: 43)              |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank_as? | 46411140.2           | -            |
| SinFastBlank - blank?    | 40815217.2           | 1.1x slower  |
| FastBlank - blank_as?    | 4996306.8            | 9.3x slower  |
| Scratch - blank_b?       | 4853033.7            | 9.6x slower  |
| Scratch - blank_f?       | 4829616.2            | 9.6x slower  |
| FastBlank - blank?       | 4649250.1            | 10.0x slower |
| Scratch - blank_c?       | 4429305.0            | 10.5x slower |
| Scratch - blank_g?       | 4399305.0            | 10.5x slower |
| ActiveSupport - blank?   | 4370875.4            | 10.6x slower |
| Scratch - blank_d?       | 3595598.2            | 12.9x slower |
| Scratch - blank_h?       | 3582028.4            | 13.0x slower |
| Scratch - blank_a?       | 2270423.1            | 20.4x slower |
| Scratch - blank_e?       | 2256574.9            | 20.6x slower |
+--------------------------+----------------------+--------------+

+----------------------------------------------------------------+
|             Benchmark Result (String Length: 127)              |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank?    | 120977730.0          | -            |
| SinFastBlank - blank_as? | 112810573.7          | -            |
| FastBlank - blank?       | 49093569.0           | 2.5x slower  |
| FastBlank - blank_as?    | 47061145.5           | 2.6x slower  |
| Scratch - blank_c?       | 13570687.1           | 8.9x slower  |
| ActiveSupport - blank?   | 13318959.9           | 9.1x slower  |
| Scratch - blank_g?       | 13204886.6           | 9.2x slower  |
| Scratch - blank_a?       | 10469203.3           | 11.6x slower |
| Scratch - blank_e?       | 10386375.9           | 11.6x slower |
| Scratch - blank_h?       | 7938442.5            | 15.2x slower |
| Scratch - blank_d?       | 7832468.5            | 15.4x slower |
| Scratch - blank_f?       | 5927205.6            | 20.4x slower |
| Scratch - blank_b?       | 5889434.8            | 20.5x slower |
+--------------------------+----------------------+--------------+

+----------------------------------------------------------------+
|             Benchmark Result (String Length: 238)              |
+--------------------------+----------------------+--------------+
| Name                     | Iteration Per Second | Speed Ratio  |
+--------------------------+----------------------+--------------+
| SinFastBlank - blank?    | 121003561.3          | -            |
| SinFastBlank - blank_as? | 112941095.0          | -            |
| FastBlank - blank?       | 49090217.3           | 2.5x slower  |
| FastBlank - blank_as?    | 47049786.2           | 2.6x slower  |
| Scratch - blank_c?       | 12137281.3           | 10.0x slower |
| Scratch - blank_g?       | 11913587.9           | 10.2x slower |
| ActiveSupport - blank?   | 11837304.0           | 10.2x slower |
| Scratch - blank_e?       | 9040110.8            | 13.4x slower |
| Scratch - blank_a?       | 9022153.0            | 13.4x slower |
| Scratch - blank_d?       | 7291766.8            | 16.6x slower |
| Scratch - blank_h?       | 7270620.6            | 16.6x slower |
| Scratch - blank_f?       | 4102725.3            | 29.5x slower |
| Scratch - blank_b?       | 4014640.7            | 30.1x slower |
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
