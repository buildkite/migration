# frozen_string_literal: true

module BK
  module Compat
    # wrapper to render text with colors when appropriate
    class Renderer
      require 'rouge'
      require 'json'
      require 'yaml'

      module Format
        YAML = :yaml
        JSON = :json
      end

      def initialize(structure)
        @structure = structure
      end

      def render(colors: STDOUT.tty?, format: Format::YAML)
        case format
        when Format::YAML
          text = JSON.parse(@structure.to_json).to_yaml
          lexer = Rouge::Lexers::YAML.new
        when Format::JSON
          # Add a new line so it outputs nicely in terminals
          text = JSON.pretty_generate(@structure)
          text += "\n"
          lexer = Rouge::Lexers::JSON.new
        else
          raise ArgumentError, "Unknown format `#{format.inspect}`"
        end

        if colors
          formatter = Rouge::Formatters::Terminal256.new(Rouge::Themes::Base16.new)
          formatter.format(lexer.lex(text))
        else
          text
        end
      end
    end
  end
end
