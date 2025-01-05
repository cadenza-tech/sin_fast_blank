# frozen_string_literal: false

$VERBOSE = nil

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'benchmark/ips'

class ::String
  def blank_a?
    !!(self =~ /\A[[:space:]]*\z/)
  end

  def blank_b?
    empty? || (self !~ /[[:^space:]]/)
  end
end

class SinFastBlankBenchmark
  STRINGS = [
    '',
    "\r\n\v\f\r\s\t ",
    'Lorem ipsum',
    '    Lorem ipsum',
    '    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
  ].freeze

  def self.execute
    STRINGS.each do |string|
      puts "\n======================== Benchmark String Length: #{string.length} ========================"

      Benchmark.ips do |x|
        ::String.class_eval { undef_method(:blank?) if method_defined?(:blank?) }

        $LOADED_FEATURES.reject! { |f| f.include?('sin_fast_blank') }
        require 'sin_fast_blank'

        x.report('FastBlank-blank_as?') do |times|
          i = 0
          while i < times
            string.blank_as?
            i += 1
          end
        end

        x.report('FastBlank-blank?') do |times|
          i = 0
          while i < times
            string.blank?
            i += 1
          end
        end

        ::String.class_eval { undef_method(:blank?) if method_defined?(:blank?) }

        $LOADED_FEATURES.reject! { |f| f.include?('active_support/core_ext/object/blank.rb') }
        require 'active_support/core_ext/object/blank'

        x.report('ActiveSupport-blank?') do |times|
          i = 0
          while i < times
            string.blank?
            i += 1
          end
        end

        x.report('Scratch-blank_a?') do |times|
          i = 0
          while i < times
            string.blank_a?
            i += 1
          end
        end

        x.report('Scratch-blank_b?') do |times|
          i = 0
          while i < times
            string.blank_b?
            i += 1
          end
        end

        x.compare!
      end
    end
  end
end
