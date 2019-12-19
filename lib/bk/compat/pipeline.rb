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

      class CommandStep
        attr_accessor :label, :key, :commands, :plugins, :depends_on

        def initialize(label: nil, key: nil, commands: [], plugins: [], depends_on: nil)
          @label = label
          @commands = commands
          @key = key
          @plugins = plugins
          @depends_on = depends_on
        end

        def to_h
          { label: @label, key: @key, commands: @commands }.tap do |h|
            h[:depends_on] = @depends_on if @depends_on
            h[:plugins] = @plugins.map(&:to_h) if @plugins && !@plugins.empty?
          end
        end
      end

      class GroupStep
        attr_accessor :label, :key, :steps

        def initialize(label: nil, key: nil, steps: [])
          @label = label
          @key = key
          @steps = steps
        end

        def to_h
          { group: @label, key: @key, steps: @steps.map(&:to_h) }
        end
      end

      attr_accessor :steps

      def initialize(steps: [])
        @steps = steps
      end

      def render(*args)
        BK::Compat::Renderer.new(to_h).render(*args)
      end

      def to_h
        { steps: steps.map(&:to_h) }
      end
    end
  end
end
