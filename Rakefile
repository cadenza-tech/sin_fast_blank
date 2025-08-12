# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'rubygems/package_task'

gemspec = Gem::Specification.load("#{__dir__}/sin_fast_blank.gemspec")

if RUBY_ENGINE == 'jruby'
  require 'rake/javaextensiontask'

  Rake::JavaExtensionTask.new('sin_fast_blank', gemspec) do |task|
    task.ext_dir = 'ext/java'
    task.source_version = '1.8'
    task.target_version = '1.8'
  end
else
  require 'rake/extensiontask'

  Rake::ExtensionTask.new('sin_fast_blank', gemspec) do |task|
    task.lib_dir = 'lib/sin_fast_blank'
  end
end

Gem::PackageTask.new(gemspec)

Rake::TestTask.new(:test) do |task|
  task.pattern = 'test/**/test_*.rb'
end

RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ['--format', ENV['RUBOCOP_FORMAT']] if ENV['RUBOCOP_FORMAT']
end

task benchmark: [:compile] do
  RubyVM::YJIT.enable if defined?(RubyVM::YJIT) && !RubyVM::YJIT.enabled?

  require_relative 'script/blank_benchmark'

  BlankBenchmark.run
end
