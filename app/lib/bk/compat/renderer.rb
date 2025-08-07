# frozen_string_literal: true

module BK
  module Compat
    # wrapper to render text with colors when appropriate
    class Renderer
      require 'rouge'
      require 'json'
      require 'yaml'

      module Format
        # whatever is here needs to define the corresponding
        # text_X and lexer_x methods
        YAML = :yaml
        JSON = :json
      end

      def initialize(structure)
        @structure = structure
        @rouge = Rouge::Formatters::Terminal256.new(Rouge::Themes::Base16.new)
      end

      def render(colors: $stdout.tty?, format: Format::YAML)
        text = send("text_#{format}")

        if colors
          lexer = send("lexer_#{format}")
          @rouge.format(lexer.lex(text))
        else
          text
        end
      rescue NoMethodError
        raise ArgumentError, "Unknown format `#{format.inspect}`"
      end

      private

      def lexer_json
        Rouge::Lexers::JSON.new
      end

      def lexer_yaml
        Rouge::Lexers::YAML.new
      end

      # prevent leading colon in YAML keys (see https://github.com/ruby/psych/issues/396)
      class SymbolToStringYamlTreeVisitor < Psych::Visitors::YAMLTree
        def visit_Symbol(sym) # rubocop:disable Naming/MethodName -- this is a Psych method
          visit_String(sym.to_s)
        end
      end

      # prevent quoting single parenthesis in a line (used for commants)
      class CustomEmitter < Psych::TreeBuilder
        def scalar(*, **)
          s = super
          s.style = Psych::Nodes::Scalar::PLAIN if s.value.match(/^[()]$/)
          s
        end
      end

      def text_yaml
        visitor = SymbolToStringYamlTreeVisitor.create({}, CustomEmitter.new)
        visitor << @structure
        visitor.tree.yaml
      end

      def text_json
        JSON.pretty_generate(@structure)
      end
    end
  end
end
