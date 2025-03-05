# frozen_string_literal: false

$VERBOSE = nil

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'json'
require 'benchmark/ips'
require 'sin_fast_blank'
require_relative 'benchmark_strings'

result = {}

BENCHMARK_STRINGS.each do |string|
  result[string.length] = {}

  report = Benchmark.ips do |x|
    x.quiet = true

    x.report('SinFastBlank - blank?') do |times|
      i = 0
      while i < times
        string.blank?
        i += 1
      end
    end

    x.report('SinFastBlank - ascii_blank?') do |times|
      i = 0
      while i < times
        string.ascii_blank?
        i += 1
      end
    end
  end

  report.entries.each do |entry|
    result[string.length][entry.label] = entry.ips
  end
end

File.write(File.expand_path('../tmp/sin_fast_blank_benchmark_results.json', __dir__), JSON.pretty_generate(result))
