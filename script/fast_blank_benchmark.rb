# frozen_string_literal: false

$VERBOSE = nil

require 'json'
require 'benchmark/ips'
require 'fast_blank'
require_relative 'benchmark_strings'

result = {}

BENCHMARK_STRINGS.each do |string|
  result[string.length] = {}

  report = Benchmark.ips do |x|
    x.quiet = true

    x.report('FastBlank - blank_as?') do |times|
      i = 0
      while i < times
        string.blank_as?
        i += 1
      end
    end

    x.report('FastBlank - blank?') do |times|
      i = 0
      while i < times
        string.blank?
        i += 1
      end
    end
  end

  report.entries.each do |entry|
    result[string.length][entry.label] = entry.ips
  end
end

File.write(File.expand_path('../tmp/fast_blank_benchmark_results.json', __dir__), JSON.pretty_generate(result))
