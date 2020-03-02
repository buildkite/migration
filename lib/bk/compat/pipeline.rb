module BK
  module Compat
    class Pipeline
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
        attr_accessor :label, :key, :commands, :plugins, :depends_on, :soft_fail, :env

        def initialize(label: nil, key: nil, commands: [], plugins: [], depends_on: nil, soft_fail: nil, env: nil)
          self.label = label
          self.commands = commands
          self.key = key
          self.plugins = plugins
          self.depends_on = depends_on
          self.soft_fail = soft_fail
          self.env = env
        end

        def commands=(value)
          @commands = [*value]
        end

        def to_h
          {}.tap do |h|
            h[:key] = @key if @key
            h[:label] = @label if @label
            if @commands.is_a?(Array)
              if @commands.length == 1
                h[:command] = @commands.first
              elsif @commands.length > 1
                h[:commands] = @commands
              end
            end
            h[:env] = @env unless @env.nil?
            h[:depends_on] = @depends_on if @depends_on
            h[:plugins] = @plugins.map(&:to_h) if @plugins && !@plugins.empty?
            h[:soft_fail] = @soft_fail unless @soft_fail.nil?
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

      def render(**args)
        BK::Compat::Renderer.new(to_h).render(**args)
      end

      def to_h
        { steps: steps.map(&:to_h) }
      end
    end
  end
end
