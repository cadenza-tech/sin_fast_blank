# frozen_string_literal: false

module ScratchBlankMethods
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
