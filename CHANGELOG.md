# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.1] - 2026-02-22

### Changed

- Improve SIMD performance with range-based approach and add `ascii_blank?` SIMD support
- Refactor Java extension
- Format C and Java code
- Add C and Java lint CI jobs
- Upgrade actions/checkout to v6
- Pin gem versions
- Add .clang-format configuration
- Improve benchmark
- Update README.md
- Update .gitignore

### Fixed

- Fix Java extension compatibility checks
- Fix C extension ARM NEON and pointer safety issues
- Fix benchmark
- Fix clang-format lint path

## [4.0.0] - 2025-08-13

### Changed

- Improve performance
- Update tests
- Update benchmark
- Update .rubocop.yml
- Improve test CI
- Improve lint CI
- Update .gitignore
- Update README.md

## [3.1.1] - 2025-03-18

### Fixed

- Fix test CI

### Changed

- Update summary

## [3.1.0] - 2025-03-12

### Changed

- Refactor implementation
- Update summary

### Fixed

- Fix test

## [3.0.0] - 2025-03-05

### Changed

- Rename `String#blank_as?` to `String#blank?`
- Rename `String#blank?` to `String#ascii_blank?`
- Update tests
- Update benchmark
- Update README.md

## [2.2.1] - 2025-03-03

### Changed

- Update tests
- Update summary

### Fixed

- Fix benchmark

## [2.2.0] - 2025-03-02

### Added

- Add .editorconfig

### Changed

- Improve performance
- Update benchmark
- Update .rubocop.yml
- Update summary
- Update README.md

## [2.1.0] - 2025-01-17

### Changed

- Improve gemspec
- Improve test CI

## [2.0.0] - 2025-01-06

### Added

- Add bin

### Changed

- Improve implementation
- Improve tests
- Update .gitignore
- Update Gemfile
- Update gemspec
- Improve CI
- Improve documents

### Removed

- Drop runtime support for Ruby 2.2 and below

## [1.0.1] - 2021-08-16/2021-12-06

### Added

- Support JRuby

### Changed

- Avoid warnings if redefining blank?

## [1.0.0] - 2015-08-03

### Added

- Ruby 2.2 support ([@tjschuck](https://github.com/tjschuck) — [#9](https://github.com/SamSaffron/fast_blank/pull/9))

## [0.0.2] - 2013-11-20

### Changed

- Unrolled internal loop to improve perf ([@tmm1](https://github.com/tmm1) — [#2](https://github.com/SamSaffron/fast_blank/pull/2))

### Removed

- Removed rake dependency ([@tmm1](https://github.com/tmm1) — [#2](https://github.com/SamSaffron/fast_blank/pull/2))

## [0.0.1] - 2013-04-07

### Added

- Initial release

[4.0.1]: https://github.com/cadenza-tech/sin_fast_blank/compare/v4.0.0...v4.0.1
[4.0.0]: https://github.com/cadenza-tech/sin_fast_blank/compare/v3.1.1...v4.0.0
[3.1.1]: https://github.com/cadenza-tech/sin_fast_blank/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/cadenza-tech/sin_fast_blank/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/cadenza-tech/sin_fast_blank/compare/v2.2.1...v3.0.0
[2.2.1]: https://github.com/cadenza-tech/sin_fast_blank/compare/v2.2.0...v2.2.1
[2.2.0]: https://github.com/cadenza-tech/sin_fast_blank/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/cadenza-tech/sin_fast_blank/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/cadenza-tech/sin_fast_blank/compare/v1.0.1...v2.0.0
[1.0.1]: https://github.com/cadenza-tech/sin_fast_blank/compare/1.0.0...v1.0.1
[1.0.0]: https://github.com/cadenza-tech/sin_fast_blank/compare/0.0.2...1.0.0
[0.0.2]: https://github.com/cadenza-tech/sin_fast_blank/compare/0.0.1...0.0.2
[0.0.1]: https://github.com/cadenza-tech/sin_fast_blank/releases/tag/0.0.1
