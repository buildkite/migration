module BK
  module Compat
    class Pipeline
      require "json"

      class Plugin
        def initialize(path:, config: nil)
          @path = path
          @config = config
        end

        def to_h
          { @path => @config }
        end
      end

      class Step
        attr_accessor :label, :key, :commands, :plugins

        def initialize(label: nil, key: nil, commands: [], plugins: [])
          @label = label
          @commands = commands
          @key = key
          @plugins = plugins
        end

        def render
          to_h.each_with_object([]) do |(key, value), buffer|
            if value.is_a?(Array)
              buffer << <<~YAML.chomp
              #{key}:
              #{value.map { |v| "  - #{v.inspect}" }.join("\n")}
              YAML
            else
              buffer << "#{key}: #{value.inspect}"
            end
          end.join("\n")
        end

        def to_h
          { label: @label, key: @key, commands: @commands, plugins: @plugins.map(&:to_h) }
        end
      end

      attr_accessor :steps

      def initialize(steps: [])
        @steps = steps
      end

      def render
        rendered_steps = steps.map(&:render).each_with_object([]) do |s, buffer|
          x = []
          s.split("\n").each_with_index do |line, index|
            if index == 0
              x << " - #{line}"
            else
              x << "   #{line}"
            end
          end
          buffer << x.join("\n")
        end

        <<~YAML
        steps:
        #{rendered_steps.join("\n\n")}
        YAML
      end

      def to_h
        { steps: steps.map(&:to_h) }
      end
    end
  end
end
