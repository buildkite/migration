require "rouge"

module BK
  module Compat
    class Renderer
      module Format
        YAML = :yaml
        JSON = :json
      end

      def initialize(structure)
        @structure = structure
      end

      def render(colors: true, format: Format::YAML)
        case format
        when Format::YAML
          text = JSON.parse(@structure.to_json).to_yaml
          lexer = Rouge::Lexers::YAML.new
        when Format::JSON
          text = JSON.pretty_generate(@structure)
          lexer = Rouge::Lexers::JSON.new
        else
          raise ArgumentError.new("Unknown format `#{format.inspect}`")
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
