# frozen_string_literal: false

$VERBOSE = nil

require 'json'
require 'benchmark/ips'
require_relative 'benchmark_strings'

class ::String
  def blank_a?
    !/[^[:space:]]/.match?(self)
  end

  def blank_b?
    self !~ /[[:^space:]]/
  end

  def blank_c?
    /\A[[:space:]]*\z/.match?(self)
  end

  def blank_d?
    !!(self =~ /\A[[:space:]]*\z/)
  end

  def blank_e?
    empty? || !/[^[:space:]]/.match?(self)
  end

  def blank_f?
    empty? || (self !~ /[[:^space:]]/)
  end

  def blank_g?
    empty? || /\A[[:space:]]*\z/.match?(self)
  end

  def blank_h?
    empty? || !!(self =~ /\A[[:space:]]*\z/)
  end
end

result = {}

BENCHMARK_STRINGS.each do |string| # rubocop:disable Metrics/BlockLength
  result[string.length] = {}

  report = Benchmark.ips do |x| # rubocop:disable Metrics/BlockLength
    x.quiet = true

    x.report('Scratch - blank_a?') do |times|
      i = 0
      while i < times
        string.blank_a?
        i += 1
      end
    end

    x.report('Scratch - blank_b?') do |times|
      i = 0
      while i < times
        string.blank_b?
        i += 1
      end
    end

    x.report('Scratch - blank_c?') do |times|
      i = 0
      while i < times
        string.blank_c?
        i += 1
      end
    end

    x.report('Scratch - blank_d?') do |times|
      i = 0
      while i < times
        string.blank_d?
        i += 1
      end
    end

    x.report('Scratch - blank_e?') do |times|
      i = 0
      while i < times
        string.blank_e?
        i += 1
      end
    end

    x.report('Scratch - blank_f?') do |times|
      i = 0
      while i < times
        string.blank_f?
        i += 1
      end
    end

    x.report('Scratch - blank_g?') do |times|
      i = 0
      while i < times
        string.blank_g?
        i += 1
      end
    end

    x.report('Scratch - blank_h?') do |times|
      i = 0
      while i < times
        string.blank_h?
        i += 1
      end
    end
  end

  report.entries.each do |entry|
    result[string.length][entry.label] = entry.ips
  end
end

File.write(File.expand_path('../tmp/scratch_benchmark_results.json', __dir__), JSON.pretty_generate(result))
