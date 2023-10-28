# frozen_string_literal: true

require_relative 'compat/parsers'

module BK
  # Wrapper to try to guess compatibility parsers
  module Compat
    VERSION = '0.1'

    PARSERS = BK::Compat::Parsers.new.plugins

    def self.guess(text)
      PARSERS.find do |parser|
        parser.matches?(text)
      end
    end

    def self.xxand(first, second, separator = '&&')
      if first.to_s.empty? && second.to_s.empty?
        nil
      elsif !first.to_s.empty? && !second.to_s.empty?
        "(#{first}) #{separator} (#{second})"
      else
        # one of them is empty we don't care which
        "#{first}#{second}"
      end
    end

    # ensure string is a valid(ish) shell variable name
    def self.var_name(id, prefix = nil)
      [
        prefix,
        id.gsub(/[^A-Za-z0-9_]/, '_').upcase
      ].compact.join('_')
    end
  end
end
