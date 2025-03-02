# frozen_string_literal: true

require_relative 'lib/sin_fast_blank/version'

Gem::Specification.new do |spec|
  spec.name = 'sin_fast_blank'
  spec.version = SinFastBlank::VERSION
  spec.description = <<~DESCRIPTION
    Ruby extension library for up to 3x faster blank string checking than fast_blank gem.
    Forked from FastBlank.
  DESCRIPTION
  spec.summary = 'Ruby extension library for up to 3x faster blank string checking than fast_blank gem.'
  spec.authors = ['Masahiro']
  spec.email = ['watanabe@cadenza-tech.com']
  spec.license = 'MIT'

  github_root_uri = 'https://github.com/cadenza-tech/sin_fast_blank'
  spec.homepage = "#{github_root_uri}/tree/v#{spec.version}"
  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{github_root_uri}/blob/v#{spec.version}/CHANGELOG.md",
    'bug_tracker_uri' => "#{github_root_uri}/issues",
    'documentation_uri' => "https://rubydoc.info/gems/#{spec.name}/#{spec.version}",
    'funding_uri' => 'https://patreon.com/CadenzaTech',
    'rubygems_mfa_required' => 'true'
  }

  spec.required_ruby_version = '>= 2.3.0'
  spec.metadata['required_jruby_version'] = '>= 9.3.0.0'
  spec.metadata['required_truffleruby_version'] = '>= 22.0.0'
  spec.metadata['required_truffleruby+graalvm_version'] = '>= 22.0.0'

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files]) do |ls|
    ls.readlines("\x0").map { |f| f.chomp("\x0") }.reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ ext/ script/ test/ spec/ features/ .git .github .editorconfig .rubocop.yml appveyor CODE_OF_CONDUCT.md Gemfile]) ||
        Dir['lib/**/*.jar'].include?(f)
    end
  end

  if RUBY_ENGINE == 'jruby'
    spec.platform = 'java'
    spec.files += Dir['lib/**/*.jar'] + Dir['ext/**/*.java']
  else
    spec.platform = Gem::Platform::RUBY # rubocop:disable Gemspec/DuplicatedAssignment
    spec.files += ['ext/sin_fast_blank/sin_fast_blank.c', 'ext/sin_fast_blank/extconf.rb']
    spec.extensions = ['ext/sin_fast_blank/extconf.rb']
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
