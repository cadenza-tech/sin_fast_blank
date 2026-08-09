# frozen_string_literal: false

require 'benchmark/ips'
require 'terminal-table'
require_relative 'benchmark_helper'
require_relative 'benchmark_strings'

class BlankBenchmark
  # Above this the ratios move from one run to the next, so the table is not one to copy into the
  # README. Every row prints its own error either way, but reading each of them is the check that
  # gets skipped.
  ERROR_PERCENTAGE_THRESHOLD = 5.0
  # The two groups answer different questions: only the first calls U+3000 and U+00A0 blank, and the
  # ASCII-only pair returns false for both. Ranking them together prints a speed ratio between methods
  # that were never asked to do the same work, so each group is reported on its own.
  BENCHMARK_GROUPS = {
    'ActiveSupport-compatible' => {
      'FastBlank' => [:fast_blank_as?],
      'SinFastBlank' => [:sin_blank?],
      'ActiveSupport' => [:as_blank?],
      'Scratch' => [:blank_a?, :blank_b?, :blank_c?, :blank_d?, :blank_e?, :blank_f?, :blank_g?, :blank_h?]
    },
    'ASCII-only' => {
      'FastBlank' => [:fast_blank?],
      'SinFastBlank' => [:sin_ascii_blank?]
    }
  }.freeze
  BENCHMARK_METHODS = BENCHMARK_GROUPS.values.flat_map(&:values).flatten.freeze

  # Sending the method name on each iteration measures the dispatch along with the method, and it
  # costs whichever method is fastest the most: on the SinFastBlank entries it takes 5-12% of their
  # throughput, the size of the gap being reported. These loops name the method outright instead.
  # benchmark-ips enters one of them once per cycle, so the public_send that picks the loop is paid
  # once per batch rather than once per call.
  LOOPS = Module.new do
    BENCHMARK_METHODS.each do |method|
      module_eval(
        # def self.#{method}(string, times)
        #   i = 0
        #   while i < times
        #     string.#{method}
        #     i += 1
        #   end
        # end
        <<~RUBY, __FILE__, __LINE__ + 1
          def self.#{method}(string, times)
            i = 0
            while i < times
              string.#{method}
              i += 1
            end
          end
        RUBY
      )
    end
  end

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

      BENCHMARK_GROUPS.each do |group_name, methods_by_library|
        report = run_benchmark(string, methods_by_library)

        results[[string.length, group_name]] = report.entries.map { |entry| [entry.label, measurement(entry)] }.to_h
      end
    end

    results
  end

  def measurement(entry)
    { ips: entry.ips, error: entry.error_percentage }
  end

  def run_benchmark(string, methods_by_library)
    Benchmark.ips do |x|
      x.time = 5
      x.warmup = 5
      x.quiet = true

      methods_by_library.each do |lib_name, methods|
        methods.each do |method|
          x.report("#{lib_name} - #{method}") { |times| LOOPS.public_send(method, string, times) }
        end
      end
    end
  end

  def display_results(all_results)
    all_results.each do |(string_length, group_name), results|
      title = "String Length: #{string_length}, #{group_name}"

      puts "\n#{create_result_table(title, results)}"
      warn_about_noise(title, results)
    end
  end

  def warn_about_noise(title, results)
    noisy = results.select { |_label, value| value[:error] > ERROR_PERCENTAGE_THRESHOLD }.sort_by { |_label, value| -value[:error] }
    return if noisy.empty?

    puts "Warning: #{title} was measured above ±#{ERROR_PERCENTAGE_THRESHOLD}%, " \
         'so its ratios are not steady enough to publish:'
    noisy.each { |label, value| puts "  #{display_label(label)} ±#{format('%.2f', value[:error])}%" }
  end

  def create_result_table(title, results)
    Terminal::Table.new(
      title: "Benchmark Result (#{title})",
      headings: ['Name', 'Iteration Per Second', 'Error', 'Speed Ratio'],
      rows: format_result_rows(results)
    )
  end

  def format_result_rows(results)
    sorted_results = results.sort_by { |_key, value| value[:ips] }.reverse
    fastest = sorted_results.first[1]
    sorted_results.map do |key, value|
      [display_label(key), format('%.1f', value[:ips]), format('±%.2f%%', value[:error]), calculate_speed_ratio(fastest, value)]
    end
  end

  # Anchored on the separator: sub replaces the first match anywhere, and an unanchored pattern
  # would eat a library name that happened to start the same way.
  def display_label(label)
    label.sub(/ - (?:fast|sin|as)_/, ' - ')
  end

  # Two entries are indistinguishable when the noise both were measured with leaves them unseparated.
  # The flat 10% this replaces sat above the measured error at most string lengths and below it at
  # length 0, where the methods run fast enough for the noise to dominate.
  def calculate_speed_ratio(fastest, current)
    speed_ratio = (fastest[:ips] / current[:ips]).round(1)
    # A ratio that rounds to 1.0 reads as slower while saying the two ran at the same speed, so it is
    # a tie on its own terms. It also answers the fastest row, whose zero gap does not fall inside a
    # zero-width band.
    return 'Fastest' if speed_ratio <= 1.0 || overlapping_error_bands?(fastest, current)

    "#{speed_ratio}x slower"
  end

  # The bands are compared as iterations rather than as the two percentages, which are each a share of
  # a different mean: adding them would shrink the fastest row's half of the band by exactly the ratio
  # being judged.
  def overlapping_error_bands?(fastest, current)
    current[:ips] * (1 + (current[:error] / 100)) > fastest[:ips] * (1 - (fastest[:error] / 100))
  end
end

BlankBenchmark.run if __FILE__ == $PROGRAM_NAME
