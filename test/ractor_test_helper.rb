# frozen_string_literal: true

module RactorTestHelper
  def in_ractor(&block)
    # Ractor itself ships with CRuby 3.0, but its 3.0 implementation is too unstable to exercise in CI.
    skip('Ractor test runs on CRuby 3.1+ only') unless RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.1')

    # Ractor.new emits a once-per-process experimental warning; keep it out of the test output.
    experimental = Warning[:experimental]
    begin
      Warning[:experimental] = false
      ractor = Ractor.new(&block)
    ensure
      Warning[:experimental] = experimental
    end

    # Ractor#take was replaced by Ractor#value: 3.4 has only the former, 4.0 only the latter.
    ractor.respond_to?(:value) ? ractor.value : ractor.take
  end
end

Minitest::Test.include(RactorTestHelper)
