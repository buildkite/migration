# frozen_string_literal: true

require_relative '../environment'

module BK
  module Compat
    # simple waiting step
    class WaitStep
      def to_h
        'wait'
      end

      def <<(_obj)
        raise 'Can not add to a wait step'
      end
    end

    # basic command step
    class CommandStep
      attr_accessor :agents, :conditional, :depends_on, :key, :label, :plugins, :soft_fail
      attr_reader :commands, :env # we define special writers

      def list_attributes
        %w[commands depends_on plugins]
      end

      def hash_attributes
        %w[agents env]
      end

      def initialize(**kwargs)
        kwargs.map do |k, v|
          # set attributes passed through as-is
          send("#{k}=", v)
        end

        # nil as default are not acceptable
        list_attributes.each { |k| send("#{k}=", []) unless kwargs.include?(k) }
        hash_attributes.each { |k| send("#{k}=", {}) unless kwargs.include?(k) }
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
          h[:env] = @env.to_h unless @env.empty?
          h[:depends_on] = @depends_on unless @depends_on.empty?
          h[:plugins] = @plugins.map(&:to_h) unless @plugins.empty?
          h[:soft_fail] = @soft_fail unless @soft_fail.nil?
          h[:if] = @conditional unless @conditional.nil?
        end
      end

      def <<(new_step)
        raise 'Can not add a wait step to another step' if new_step.is_a?(BK::Compat::WaitStep)

        if new_step.is_a?(self.class)
          env.merge!(new_step.env)
          @agents.merge!(new_step.agents)
          @commands.concat(new_step.commands)
          @plugins.concat(new_step.plugins)

          # TODO: add soft_fail, depends and ifs
          @depends_on.concat(new_step.commands)
        elsif new_step.is_a?(BK::Compat::Plugin)
          @plugins << new_step
        else
          @commands.concat(new_step)
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
  end
end
