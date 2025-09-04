# frozen_string_literal: false

module ScratchBlankMethods
  BLANK_A_REGEXP = /[^[:space:]]/.freeze
  BLANK_B_REGEXP = /[[:^space:]]/.freeze
  BLANK_C_REGEXP = /\A[[:space:]]*\z/.freeze
  BLANK_D_REGEXP = /\A[[:space:]]*\z/.freeze
  BLANK_E_REGEXP = /[^[:space:]]/.freeze
  BLANK_F_REGEXP = /[[:^space:]]/.freeze
  BLANK_G_REGEXP = /\A[[:space:]]*\z/.freeze
  BLANK_H_REGEXP = /\A[[:space:]]*\z/.freeze

  def blank_a?
    !BLANK_A_REGEXP.match?(self)
  end

  def blank_b?
    self !~ BLANK_B_REGEXP
  end

  def blank_c?
    BLANK_C_REGEXP.match?(self)
  end

  def blank_d?
    !!(self =~ BLANK_D_REGEXP)
  end

  def blank_e?
    empty? || !BLANK_E_REGEXP.match?(self)
  end

  def blank_f?
    empty? || (self !~ BLANK_F_REGEXP)
  end

  def blank_g?
    empty? || BLANK_G_REGEXP.match?(self)
  end

  def blank_h?
    empty? || !!(self =~ BLANK_H_REGEXP)
  end
end
