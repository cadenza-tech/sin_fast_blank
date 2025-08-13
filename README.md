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

SinFastBlank's String#blank? is about 1.8-16.2x faster than FastBlank's String#blank_as? and about 1.4-27.7x faster than ActiveSupport's String#blank?.

Additionally, this gem allocates no strings during the check, making it less of a burden on the GC.

```bash
$ bundle exec rake benchmark

+-------------------------------------------------------------------+
|                Benchmark Result (String Length: 0)                |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| FastBlank - blank_as?       | 130269964.9          | Fastest      |
| SinFastBlank - blank?       | 130244308.1          | Fastest      |
| FastBlank - blank?          | 120829438.2          | Fastest      |
| SinFastBlank - ascii_blank? | 102607554.2          | 1.3x slower  |
| ActiveSupport - blank?      | 93735326.8           | 1.4x slower  |
| Scratch - blank_e?          | 33719107.1           | 3.9x slower  |
| Scratch - blank_f?          | 22852667.2           | 5.7x slower  |
| Scratch - blank_g?          | 22591245.7           | 5.8x slower  |
| Scratch - blank_h?          | 22496363.0           | 5.8x slower  |
| Scratch - blank_a?          | 15513753.7           | 8.4x slower  |
| Scratch - blank_b?          | 9098466.9            | 14.3x slower |
| Scratch - blank_c?          | 8667858.7            | 15.0x slower |
| Scratch - blank_d?          | 4011918.0            | 32.5x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|                Benchmark Result (String Length: 8)                |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - blank?       | 70389249.9           | Fastest      |
| SinFastBlank - ascii_blank? | 64618842.4           | Fastest      |
| FastBlank - blank?          | 29619190.3           | 2.4x slower  |
| FastBlank - blank_as?       | 27389477.0           | 2.6x slower  |
| ActiveSupport - blank?      | 9415354.3            | 7.5x slower  |
| Scratch - blank_c?          | 8283562.7            | 8.5x slower  |
| Scratch - blank_b?          | 8268956.6            | 8.5x slower  |
| Scratch - blank_g?          | 7120165.8            | 9.9x slower  |
| Scratch - blank_f?          | 7117525.5            | 9.9x slower  |
| Scratch - blank_a?          | 5735881.1            | 12.3x slower |
| Scratch - blank_e?          | 5437609.2            | 12.9x slower |
| Scratch - blank_d?          | 3904138.1            | 18.0x slower |
| Scratch - blank_h?          | 3639216.9            | 19.3x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|               Benchmark Result (String Length: 43)                |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - blank?       | 77535354.1           | Fastest      |
| SinFastBlank - ascii_blank? | 33651994.0           | 2.3x slower  |
| FastBlank - blank_as?       | 4798732.4            | 16.2x slower |
| FastBlank - blank?          | 4508316.4            | 17.2x slower |
| Scratch - blank_b?          | 3544833.1            | 21.9x slower |
| Scratch - blank_f?          | 3279077.5            | 23.6x slower |
| ActiveSupport - blank?      | 2803305.0            | 27.7x slower |
| Scratch - blank_c?          | 2715833.6            | 28.5x slower |
| Scratch - blank_g?          | 2576668.4            | 30.1x slower |
| Scratch - blank_d?          | 2384495.7            | 32.5x slower |
| Scratch - blank_h?          | 2286237.4            | 33.9x slower |
| Scratch - blank_a?          | 2172062.1            | 35.7x slower |
| Scratch - blank_e?          | 2142255.3            | 36.2x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|               Benchmark Result (String Length: 127)               |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - blank?       | 73412799.1           | Fastest      |
| SinFastBlank - ascii_blank? | 65706550.5           | 1.1x slower  |
| FastBlank - blank?          | 42671119.0           | 1.7x slower  |
| FastBlank - blank_as?       | 41159948.5           | 1.8x slower  |
| ActiveSupport - blank?      | 9369934.9            | 7.8x slower  |
| Scratch - blank_a?          | 8336468.2            | 8.8x slower  |
| Scratch - blank_c?          | 8205466.3            | 8.9x slower  |
| Scratch - blank_e?          | 7739308.1            | 9.5x slower  |
| Scratch - blank_g?          | 7059641.0            | 10.4x slower |
| Scratch - blank_d?          | 5745411.2            | 12.8x slower |
| Scratch - blank_h?          | 5214356.4            | 14.1x slower |
| Scratch - blank_b?          | 4485234.5            | 16.4x slower |
| Scratch - blank_f?          | 4163088.2            | 17.6x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|               Benchmark Result (String Length: 238)               |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - blank?       | 73768817.2           | Fastest      |
| SinFastBlank - ascii_blank? | 66551330.7           | 1.1x slower  |
| FastBlank - blank?          | 42988523.0           | 1.7x slower  |
| FastBlank - blank_as?       | 41362990.8           | 1.8x slower  |
| ActiveSupport - blank?      | 8450784.9            | 8.7x slower  |
| Scratch - blank_c?          | 7467044.7            | 9.9x slower  |
| Scratch - blank_a?          | 7249127.3            | 10.2x slower |
| Scratch - blank_e?          | 6801296.1            | 10.8x slower |
| Scratch - blank_g?          | 6529845.9            | 11.3x slower |
| Scratch - blank_d?          | 5402871.6            | 13.7x slower |
| Scratch - blank_h?          | 4930234.7            | 15.0x slower |
| Scratch - blank_b?          | 3340334.9            | 22.1x slower |
| Scratch - blank_f?          | 3146012.8            | 23.4x slower |
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
