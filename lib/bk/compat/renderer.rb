require "rouge"

module BK
  module Compat
    class Renderer
      def initialize(structure)
        @structure = structure
      end

      def render(colors: true)
        yaml = JSON.parse(@structure.to_json).to_yaml

        if colors
          formatter = Rouge::Formatters::Terminal256.new(Rouge::Themes::Base16.new)
          lexer = Rouge::Lexers::YAML.new
          formatter.format(lexer.lex(yaml))
        else
          yaml
        end
      end
    end
  end
end
