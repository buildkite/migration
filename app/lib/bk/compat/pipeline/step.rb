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
          block: @key,
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
      attr_accessor :agents, :artifact_paths, :branches, :concurrency, :concurrency_group,
                    :conditional, :depends_on, :key, :label, :matrix, :parameters, :plugins,
                    :soft_fail, :timeout_in_minutes, :transformer

      attr_reader :commands, :env # we define special writers

      LIST_ATTRIBUTES = %w[artifact_paths commands depends_on plugins].freeze
      HASH_ATTRIBUTES = %w[agents env matrix parameters].freeze

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
        clean_attributes.tap do |h|
          # special handling
          h[:plugins] = @plugins.map(&:to_h)
          h[:env] = @env&.to_h

          # remove empty and nil values
          h.delete_if { |_, v| v.nil? || (v.is_a?(Enumerable) && v.empty?) }
        end
      end

      def clean_attributes
        instance_attributes.tap do |h|
          # rename conditional to if (a reserved word as an attribute or instance variable is complicated)
          h[:if] = h.delete(:conditional)
          h.delete(:parameters)
          h.delete(:transformer)
          h.delete(:soft_fail) if h[:soft_fail] == false
          h.delete(:branches) if h[:branches] == ''
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
 #       puts "new step"
 #       p new_step.commands
        LIST_ATTRIBUTES.each { |a| 
          if a.eql?("commands") && new_step.commands.length == 1 && new_step.commands[0].start_with?("cd")
            @commands.unshift(new_step.commands[0])
          else
            send(a).concat(new_step.send(a))
          end 
        }
        HASH_ATTRIBUTES.each { |a| send(a).merge!(new_step.send(a)) }

        @conditional = BK::Compat.xxand(conditional, new_step.conditional)
        @concurrency = [@concurrency, new_step.concurrency].compact.min
        @concurrency_group ||= new_step.concurrency_group
        @branches = "#{@branches} #{new_step.branches}".strip
        @timeout_in_minutes = [@timeout_in_minutes, new_step.timeout_in_minutes].compact.max

        # TODO: these could be a hash with exit codes
        @soft_fail ||= new_step.soft_fail

        nil
      end

      def instance_attributes
        # helper method to get all instance attributes as a dictionary
        instance_variables.to_h { |v| [v.to_s.delete_prefix('@').to_sym, instance_variable_get(v)] }
      end

      def instantiate(*, **)
        unless @transformer.nil?
          params = instance_attributes.transform_values { |val| recurse_to_string(val, @transformer.to_proc, *, **) }
        end
        params.delete(:parameters)

        self.class.new(**params)
      end

      def recurse_to_string(value, block, *, **)
        case value
        when String
          block.call(value, *, **)
        when Hash
          value.transform_values! { |elem| recurse_to_string(elem, block, *, **) }
        when Array
          value.map! { |elem| recurse_to_string(elem, block, *, **) }
        else
          # if we don't know how to do this, do nothing
          value
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
