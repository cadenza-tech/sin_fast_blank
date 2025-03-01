# frozen_string_literal: false

require 'json'
require 'fileutils'
require 'terminal-table'
require_relative 'benchmark_strings'

class Benchmark
  def self.summarize # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    sin_fast_blank_benchmark_results_file_path = File.expand_path('../tmp/sin_fast_blank_benchmark_results.json', __dir__)
    fast_blank_benchmark_results_file_path = File.expand_path('../tmp/fast_blank_benchmark_results.json', __dir__)
    activesupport_benchmark_results_file_path = File.expand_path('../tmp/activesupport_benchmark_results.json', __dir__)
    scratch_benchmark_results_file_path = File.expand_path('../tmp/scratch_benchmark_results.json', __dir__)

    sin_fast_blank_benchmark_results = JSON.parse(File.read(sin_fast_blank_benchmark_results_file_path))
    fast_blank_benchmark_results = JSON.parse(File.read(fast_blank_benchmark_results_file_path))
    activesupport_benchmark_results = JSON.parse(File.read(activesupport_benchmark_results_file_path))
    scratch_benchmark_results = JSON.parse(File.read(scratch_benchmark_results_file_path))

    FileUtils.rm_f(sin_fast_blank_benchmark_results_file_path)
    FileUtils.rm_f(fast_blank_benchmark_results_file_path)
    FileUtils.rm_f(activesupport_benchmark_results_file_path)
    FileUtils.rm_f(scratch_benchmark_results_file_path)

    BENCHMARK_STRINGS.map { |s| s.length.to_s }.each do |string_length|
      results = sin_fast_blank_benchmark_results[string_length]
                .merge(fast_blank_benchmark_results[string_length])
                .merge(activesupport_benchmark_results[string_length])
                .merge(scratch_benchmark_results[string_length])
      rows = results.sort_by { |_key, value| value }.reverse.to_h
      rows = rows.map do |key, value|
        speed_ratio = rows.first[1] / value
        if speed_ratio - 1 >= 0.1
          slower_text = "#{speed_ratio.round(1)}x slower"
        else
          slower_text = '-'
        end
        [key, format('%.1f', value), slower_text]
      end

      table = Terminal::Table.new(
        title: "Benchmark Result (String Length: #{string_length})",
        headings: ['Name', 'Iteration Per Second', 'Speed Ratio'],
        rows: rows
      )

      puts "\n#{table}"
    end
  end
end
