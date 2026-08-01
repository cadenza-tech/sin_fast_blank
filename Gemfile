# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'activesupport'
gem 'benchmark-ips'
gem 'fast_blank'
if RUBY_ENGINE == 'truffleruby' && RUBY_VERSION < '3.3'
  gem 'json', '~> 2.7.6'
  gem 'minitest', '< 5.26.2'
else
  gem 'json'
  gem 'minitest'
end
gem 'rake'
gem 'rake-compiler'
gem 'rubocop'
gem 'rubocop-minitest'
gem 'rubocop-performance'
gem 'rubocop-rake'
gem 'terminal-table'
