# frozen_string_literal: false

require 'benchmark/ips'
require 'terminal-table'
require_relative 'benchmark_helper'
require_relative 'benchmark_strings'

class BlankBenchmark
  SPEED_RATIO_THRESHOLD = 0.1
  BENCHMARK_METHODS = {
    'FastBlank' => [:fast_blank_as?, :fast_blank?],
    'SinFastBlank' => [:sin_blank?, :sin_ascii_blank?],
    'ActiveSupport' => [:as_blank?],
    'Scratch' => [:blank_a?, :blank_b?, :blank_c?, :blank_d?, :blank_e?, :blank_f?, :blank_g?, :blank_h?]
  }.freeze

  def self.run
    new.run
  end

  def run
    results = run_benchmarks
    display_results(results)
  end

  private

  def run_benchmarks
    results = {}

    BENCHMARK_STRINGS.each do |string|
      puts "Benchmarking string length: #{string.length}..."

      report = run_benchmark(string)

      results[string.length] = report.entries.map { |entry| [entry.label, entry.ips] }.to_h
    end

    results
  end

  def run_benchmark(string)
    Benchmark.ips do |x|
      x.time = 5
      x.warmup = 5
      x.quiet = true

      BENCHMARK_METHODS.each do |lib_name, methods|
        methods.each do |method|
          x.report("#{lib_name} - #{method}") do |times|
            i = 0
            while i < times
              string.send(method)
              i += 1
            end
          end
        end
      end
    end
  end

  def display_results(all_results)
    all_results.each do |string_length, results|
      table = create_result_table(string_length, results)
      puts "\n#{table}"
    end
  end

  def create_result_table(string_length, results)
    Terminal::Table.new(
      title: "Benchmark Result (String Length: #{string_length})",
      headings: ['Name', 'Iteration Per Second', 'Speed Ratio'],
      rows: format_result_rows(results)
    )
  end

  def format_result_rows(results)
    sorted_results = results.sort_by { |_key, value| value }.reverse
    fastest_speed = sorted_results.first[1]
    sorted_results.map do |key, value|
      [key.sub(/(fast|sin|as)_/, ''), format('%.1f', value), calculate_speed_ratio(fastest_speed, value)]
    end
  end

  def calculate_speed_ratio(fastest_speed, current_speed)
    speed_ratio = fastest_speed / current_speed
    return 'Fastest' if speed_ratio - 1 < SPEED_RATIO_THRESHOLD

    "#{speed_ratio.round(1)}x slower"
  end
end

BlankBenchmark.run if __FILE__ == $PROGRAM_NAME
