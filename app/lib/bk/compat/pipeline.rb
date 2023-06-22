# frozen_string_literal: true

require_relative 'renderer'
require_relative 'environment'

module BK
  module Compat
    # Base BuildKite pipeline
    class Pipeline
      # Plugin to use in a step
      class Plugin
        def initialize(path:, config: nil)
          @path = path
          @config = config
        end

        def to_h
          { @path => @config }
        end
      end

      # simple waiting step
      class WaitStep
        def to_h
          'wait'
        end
      end

      # basic command step
      class CommandStep
        attr_accessor :label, :key, :commands, :agents, :plugins, :depends_on, :soft_fail, :env, :conditional

        def initialize(label: nil, key: nil, agents: [], commands: [], plugins: [], depends_on: nil, soft_fail: nil,
                       env: nil, conditional: nil)
          self.label = label
          self.commands = commands
          self.agents = agents
          self.key = key
          self.plugins = plugins
          self.depends_on = depends_on
          self.soft_fail = soft_fail
          self.env = env
          self.conditional = conditional
        end

        def commands=(value)
          @commands = [*value].flatten
        end

        def env=(value)
          @env = if value.is_a?(BK::Compat::Environment)
                   value
                 else
                   BK::Compat::Environment.new(value)
                 end
        end

        def to_h
          {}.tap do |h|
            h[:key] = @key if @key
            h[:label] = @label if @label
            h[:agents] = @agents unless @agents.empty?
            if @commands.is_a?(Array)
              if @commands.length == 1
                h[:command] = @commands.first
              elsif @commands.length > 1
                h[:commands] = @commands
              end
            end
            h[:env] = @env.to_h unless @env.nil?
            h[:depends_on] = @depends_on if @depends_on
            h[:plugins] = @plugins.map(&:to_h) if @plugins && !@plugins.empty?
            h[:soft_fail] = @soft_fail unless @soft_fail.nil?
            h[:if] = @conditional unless @conditional.nil?
          end
        end
      end

      # group step
      class GroupStep
        attr_accessor :label, :key, :steps, :conditional

        def initialize(label: nil, key: nil, steps: [], conditional: nil)
          @label = label
          @key = key
          @steps = steps
          @conditional = conditional
        end

        def to_h
          { group: @label, key: @key, steps: @steps.map(&:to_h) }.tap do |h|
            h[:if] = @conditional unless @conditional.nil?
          end
        end
      end

      attr_accessor :steps, :env

      def initialize(steps: [], env: nil)
        @steps = steps
        @env = env
      end

      def render(**args)
        BK::Compat::Renderer.new(to_h).render(**args)
      end

      def to_h
        {}.tap do |h|
          h[:env] = @env.to_h if @env
          h[:steps] = steps.map(&:to_h)
        end
      end
    end
  end
end
