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

SinFastBlank's String#blank? is about 1.8-15.8x faster than FastBlank's String#blank_as? and about 1.4-27.5x faster than ActiveSupport's String#blank?.

Additionally, this gem allocates no strings during the check, making it less of a burden on the GC.

```bash
$ bundle exec rake benchmark

+-------------------------------------------------------------------+
|                Benchmark Result (String Length: 0)                |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - blank?       | 130332717.9          | Fastest      |
| FastBlank - blank_as?       | 130073872.3          | Fastest      |
| FastBlank - blank?          | 120949518.0          | Fastest      |
| SinFastBlank - ascii_blank? | 102454885.3          | 1.3x slower  |
| ActiveSupport - blank?      | 93972240.6           | 1.4x slower  |
| Scratch - blank_e?          | 33763124.1           | 3.9x slower  |
| Scratch - blank_f?          | 22836580.0           | 5.7x slower  |
| Scratch - blank_g?          | 22702537.6           | 5.7x slower  |
| Scratch - blank_h?          | 22628556.0           | 5.8x slower  |
| Scratch - blank_a?          | 15465657.5           | 8.4x slower  |
| Scratch - blank_b?          | 8842849.9            | 14.7x slower |
| Scratch - blank_c?          | 8738787.3            | 14.9x slower |
| Scratch - blank_d?          | 4110844.4            | 31.7x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|                Benchmark Result (String Length: 8)                |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - blank?       | 70504920.9           | Fastest      |
| SinFastBlank - ascii_blank? | 64673416.3           | Fastest      |
| FastBlank - blank?          | 29594588.1           | 2.4x slower  |
| FastBlank - blank_as?       | 27436294.1           | 2.6x slower  |
| ActiveSupport - blank?      | 9397623.1            | 7.5x slower  |
| Scratch - blank_c?          | 8303597.3            | 8.5x slower  |
| Scratch - blank_b?          | 8215201.6            | 8.6x slower  |
| Scratch - blank_g?          | 7165141.6            | 9.8x slower  |
| Scratch - blank_f?          | 7052450.1            | 10.0x slower |
| Scratch - blank_a?          | 5743412.5            | 12.3x slower |
| Scratch - blank_e?          | 5377207.7            | 13.1x slower |
| Scratch - blank_d?          | 3996394.3            | 17.6x slower |
| Scratch - blank_h?          | 3725923.0            | 18.9x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|               Benchmark Result (String Length: 43)                |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - blank?       | 78204105.4           | Fastest      |
| SinFastBlank - ascii_blank? | 33538338.4           | 2.3x slower  |
| FastBlank - blank_as?       | 4955724.4            | 15.8x slower |
| FastBlank - blank?          | 4610702.1            | 17.0x slower |
| Scratch - blank_b?          | 3695753.3            | 21.2x slower |
| Scratch - blank_f?          | 3432594.5            | 22.8x slower |
| ActiveSupport - blank?      | 2847389.8            | 27.5x slower |
| Scratch - blank_c?          | 2743162.5            | 28.5x slower |
| Scratch - blank_g?          | 2590408.5            | 30.2x slower |
| Scratch - blank_d?          | 2397991.1            | 32.6x slower |
| Scratch - blank_h?          | 2299818.0            | 34.0x slower |
| Scratch - blank_a?          | 2207233.4            | 35.4x slower |
| Scratch - blank_e?          | 2156507.1            | 36.3x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|               Benchmark Result (String Length: 127)               |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - blank?       | 73614227.9           | Fastest      |
| SinFastBlank - ascii_blank? | 65866197.7           | 1.1x slower  |
| FastBlank - blank?          | 42846828.1           | 1.7x slower  |
| FastBlank - blank_as?       | 41268460.6           | 1.8x slower  |
| ActiveSupport - blank?      | 9370992.8            | 7.9x slower  |
| Scratch - blank_a?          | 8387651.6            | 8.8x slower  |
| Scratch - blank_c?          | 8264076.2            | 8.9x slower  |
| Scratch - blank_e?          | 7710409.1            | 9.5x slower  |
| Scratch - blank_g?          | 7134171.5            | 10.3x slower |
| Scratch - blank_d?          | 5801926.7            | 12.7x slower |
| Scratch - blank_h?          | 5268556.4            | 14.0x slower |
| Scratch - blank_b?          | 4630144.9            | 15.9x slower |
| Scratch - blank_f?          | 4238312.9            | 17.4x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|               Benchmark Result (String Length: 238)               |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - blank?       | 73820537.2           | Fastest      |
| SinFastBlank - ascii_blank? | 67308850.3           | Fastest      |
| FastBlank - blank?          | 42938005.9           | 1.7x slower  |
| FastBlank - blank_as?       | 41422378.7           | 1.8x slower  |
| ActiveSupport - blank?      | 8411852.3            | 8.8x slower  |
| Scratch - blank_c?          | 7536457.9            | 9.8x slower  |
| Scratch - blank_a?          | 7166373.0            | 10.3x slower |
| Scratch - blank_e?          | 6791611.4            | 10.9x slower |
| Scratch - blank_g?          | 6473386.4            | 11.4x slower |
| Scratch - blank_d?          | 5425231.6            | 13.6x slower |
| Scratch - blank_h?          | 4938394.6            | 14.9x slower |
| Scratch - blank_b?          | 3422558.9            | 21.6x slower |
| Scratch - blank_f?          | 3203359.7            | 23.0x slower |
+-----------------------------+----------------------+--------------+
```

The benchmark was executed in the following environment:

- Ruby 3.4.5 (2025-07-16 revision 20cda200d3) +YJIT +PRISM [arm64-darwin24]
- FastBlank 1.0.1
- ActiveSupport 8.0.2

Performance depends not only on the string length but also on its content.

## Development

### Building for JRuby

To build the Java extension for JRuby support, follow these steps:

1. Start a JRuby Docker container:

```bash
docker run -it --rm -v "$(pwd):/app" -w /app jruby:9.3.4.0-jdk8 /bin/bash
```

2. Install necessary dependencies:

```bash
apt update
apt upgrade
apt install git
```

3. Compile the Java source:

```bash
cd ext/java
javac -cp /opt/jruby/lib/jruby.jar sin_deep_merge/SinDeepMergeLibrary.java
```

4. Create the JAR file:

```bash
jar cvf ../../lib/sin_deep_merge/sin_deep_merge.jar sin_deep_merge/SinDeepMergeLibrary.class
```

5. Install dependencies and run linter, tests and benchmarks:

```bash
cd ../../
gem install bundler
bundle install
bundle exec rake rubocop
bundle exec rake test
bundle exec rake benchmark
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
