# frozen_string_literal: false

BENCHMARK_STRINGS = [
  '',
  "\r\n\v\f\r\s\t ",
  '\r\n\v\f\r\s\t \r\n\v\f\r\s\t \r\n\v\f\r\s\t \r\n\v\f\r\s\t Lorem ipsum',
  '    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
  '    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 🐈️'
].freeze
