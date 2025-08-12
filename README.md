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

SinFastBlank's String#blank? is about 4.2-18.6x faster than FastBlank's String#blank_as? and about 1.2-28.3x faster than ActiveSupport's String#blank?.

Additionally, this gem allocates no strings during the check, making it less of a burden on the GC.

```bash
$ bundle exec rake benchmark

+-------------------------------------------------------------------+
|                Benchmark Result (String Length: 0)                |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - blank?       | 141022820.3          | Fastest      |
| SinFastBlank - ascii_blank? | 135536051.1          | Fastest      |
| FastBlank - blank?          | 130140458.3          | Fastest      |
| ActiveSupport - blank?      | 112829779.3          | 1.2x slower  |
| Scratch - blank_e?          | 34444957.4           | 4.1x slower  |
| Scratch - blank_f?          | 33706432.6           | 4.2x slower  |
| FastBlank - blank_as?       | 28673133.2           | 4.9x slower  |
| Scratch - blank_g?          | 23012376.9           | 6.1x slower  |
| Scratch - blank_h?          | 22539321.2           | 6.3x slower  |
| Scratch - blank_a?          | 19121386.4           | 7.4x slower  |
| Scratch - blank_b?          | 9516569.6            | 14.8x slower |
| Scratch - blank_c?          | 8937123.0            | 15.8x slower |
| Scratch - blank_d?          | 4158869.4            | 33.9x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|                Benchmark Result (String Length: 8)                |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - blank?       | 73785804.3           | Fastest      |
| SinFastBlank - ascii_blank? | 73640646.8           | Fastest      |
| FastBlank - blank?          | 30673890.3           | 2.4x slower  |
| FastBlank - blank_as?       | 16158497.2           | 4.6x slower  |
| ActiveSupport - blank?      | 9592323.7            | 7.7x slower  |
| Scratch - blank_b?          | 8587487.3            | 8.6x slower  |
| Scratch - blank_c?          | 8509419.7            | 8.7x slower  |
| Scratch - blank_f?          | 7954455.7            | 9.3x slower  |
| Scratch - blank_g?          | 7320665.4            | 10.1x slower |
| Scratch - blank_a?          | 6236212.3            | 11.8x slower |
| Scratch - blank_e?          | 5505940.2            | 13.4x slower |
| Scratch - blank_d?          | 4047261.0            | 18.2x slower |
| Scratch - blank_h?          | 3789973.7            | 19.5x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|               Benchmark Result (String Length: 43)                |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - blank?       | 81008447.6           | Fastest      |
| SinFastBlank - ascii_blank? | 35356374.2           | 2.3x slower  |
| FastBlank - blank?          | 4605934.3            | 17.6x slower |
| FastBlank - blank_as?       | 4353780.8            | 18.6x slower |
| Scratch - blank_b?          | 3784575.0            | 21.4x slower |
| Scratch - blank_f?          | 3599512.4            | 22.5x slower |
| ActiveSupport - blank?      | 2862463.9            | 28.3x slower |
| Scratch - blank_c?          | 2761592.8            | 29.3x slower |
| Scratch - blank_g?          | 2621682.9            | 30.9x slower |
| Scratch - blank_d?          | 2413520.5            | 33.6x slower |
| Scratch - blank_h?          | 2315600.3            | 35.0x slower |
| Scratch - blank_a?          | 2282134.2            | 35.5x slower |
| Scratch - blank_e?          | 2175646.6            | 37.2x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|               Benchmark Result (String Length: 127)               |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - ascii_blank? | 81550165.0           | Fastest      |
| SinFastBlank - blank?       | 77110051.4           | Fastest      |
| FastBlank - blank?          | 44638431.8           | 1.8x slower  |
| FastBlank - blank_as?       | 19318819.1           | 4.2x slower  |
| ActiveSupport - blank?      | 9569196.6            | 8.5x slower  |
| Scratch - blank_a?          | 9402655.6            | 8.7x slower  |
| Scratch - blank_c?          | 8507158.8            | 9.6x slower  |
| Scratch - blank_e?          | 7894326.0            | 10.3x slower |
| Scratch - blank_g?          | 7318557.3            | 11.1x slower |
| Scratch - blank_d?          | 5888359.7            | 13.8x slower |
| Scratch - blank_h?          | 5334154.6            | 15.3x slower |
| Scratch - blank_b?          | 4740650.2            | 17.2x slower |
| Scratch - blank_f?          | 4585778.8            | 17.8x slower |
+-----------------------------+----------------------+--------------+

+-------------------------------------------------------------------+
|               Benchmark Result (String Length: 238)               |
+-----------------------------+----------------------+--------------+
| Name                        | Iteration Per Second | Speed Ratio  |
+-----------------------------+----------------------+--------------+
| SinFastBlank - ascii_blank? | 81362796.3           | Fastest      |
| SinFastBlank - blank?       | 77109321.4           | Fastest      |
| FastBlank - blank?          | 44643347.7           | 1.8x slower  |
| FastBlank - blank_as?       | 19340672.7           | 4.2x slower  |
| ActiveSupport - blank?      | 8582384.6            | 9.5x slower  |
| Scratch - blank_a?          | 8076152.4            | 10.1x slower |
| Scratch - blank_c?          | 7693549.7            | 10.6x slower |
| Scratch - blank_e?          | 6899197.1            | 11.8x slower |
| Scratch - blank_g?          | 6699382.3            | 12.1x slower |
| Scratch - blank_d?          | 5492935.4            | 14.8x slower |
| Scratch - blank_h?          | 5030383.7            | 16.2x slower |
| Scratch - blank_b?          | 3495335.4            | 23.3x slower |
| Scratch - blank_f?          | 3397400.4            | 23.9x slower |
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
