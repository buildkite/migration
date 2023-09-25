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

      def instantiate
        dup
      end
    end

    # simple block step
    class BlockStep
      attr_accessor :depends_on, :key

      def initialize(key:, depends_on: [])
        @key = key
        @depends_on = depends_on
      end

      def <<(_obj)
        raise 'Can not add to a block step'
      end

      def to_h
        {
          key: @key,
          depends_on: @depends_on
        }
      end

      def instantiate
        dup
      end
    end

    # basic command step
    class CommandStep
      attr_accessor :agents, :conditional, :depends_on, :key, :label, :plugins, :soft_fail
      attr_reader :commands, :env # we define special writers

      LIST_ATTRIBUTES = %w[commands depends_on plugins].freeze
      HASH_ATTRIBUTES = %w[agents env].freeze

      def initialize(**kwargs)
        # nil as default are not acceptable
        LIST_ATTRIBUTES.each { |k| send("#{k}=", []) }
        HASH_ATTRIBUTES.each { |k| send("#{k}=", {}) }

        kwargs.map do |k, v|
          # set attributes passed through as-is
          send("#{k}=", v)
        end

      end

      def commands=(value)
        @commands = [*value].flatten
      end

      def add_commands(*values)
        @commands.concat(values.flatten)
      end

      def prepend_commands(*values)
        @commands.prepend(*values.flatten)
      end

      def env=(value)
        @env = if value.is_a?(BK::Compat::Environment)
                 value
               else
                 BK::Compat::Environment.new(value)
               end
      end

      def to_h
        instance_attributes.tap do |h|
          # rename conditional to if (a reserved word as an attribute or instance variable is complicated)
          h[:if] = h.delete('conditional')

          # special handling
          h[:plugins] = @plugins.map(&:to_h)
          h[:env] = @env&.to_h
          h[:commands] = @commands.flatten

          # remove empty and nil values
          h.delete_if { |_, v| v.nil? || v.empty? }
        end
      end

      # add/merge step
      def <<(other)
        case other
        when BK::Compat::WaitStep
          raise 'Can not add a wait step to another step'
        when self.class
          merge!(other)
        when BK::Compat::Plugin
          @plugins << other
        else
          add_commands(*other) unless other.nil?
        end
      end

      # prepend/merge steps
      def >>(other)
        case other
        when BK::Compat::WaitStep
          raise 'Can not add a wait step to another step'
        when self.class
          other.merge!(self).tap do |step|
            step.key = key
            step.label = label
          end
        when BK::Compat::Plugin
          @plugins.prepend(other)
        else
          prepend_commands(*other) unless other.nil?
        end
      end

      def merge!(new_step)
        LIST_ATTRIBUTES.each { |a| send(a).concat(new_step.send(a)) }
        HASH_ATTRIBUTES.each { |a| send(a).merge!(new_step.send(a)) }

        @conditional = BK::Compat.xxand(conditional, new_step.conditional)

        # TODO: these could be a hash with exit codes
        @soft_fail = soft_fail || new_step.soft_fail
      end

      def instance_attributes
        # helper method to get all instance attributes as a dictionary
        instance_variables.to_h { |v| [v.to_s.delete_prefix('@').to_sym, instance_variable_get(v)] }
      end

      def instantiate(config)
        dup
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
