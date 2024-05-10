# frozen_string_literal: true

module BK
  module Compat
    # Shared behaviour among steps
    class BaseStep
      def list_attributes
        []
      end

      def hash_attributes
        []
      end

      def initialize(**kwargs)
        # nil as default are not acceptable
        list_attributes.each { |k| send("#{k}=", []) }
        hash_attributes.each { |k| send("#{k}=", {}) }

        kwargs.map do |k, v|
          # set attributes passed through as-is
          send("#{k}=", v)
        end
      end

      private

      def key_order
        %i[group block key label depends_on if agent commands].freeze
      end

      def _order(key)
        # helper method to get keys in a particular order
        key_order.index(key) || key_order.length
      end

      def instantiate
        dup
      end

      def instance_attributes
        # helper method to get all instance attributes as a dictionary
        instance_variables.to_h { |v| [v.to_s.delete_prefix('@').to_sym, instance_variable_get(v)] }
      end

      def to_h
        h = instance_attributes
        # rename conditional to if (a reserved word as an attribute or instance variable is complicated)
        h[:if] = h.delete(:conditional)

        clean_dict(h)
      end

      def clean_dict(dict)
        # remove empty and nil values
        dict.delete_if { |_, v| v.nil? || (v.is_a?(Enumerable) && v.empty?) }

        # sort values for stable and consistent outputs
        dict.sort { |a, b| _order(a[0]) - _order(b[0]) }.to_h
      end
    end

    # simple waiting step
    class WaitStep < BaseStep
      def to_h
        'wait'
      end

      def <<(_other)
        raise 'Can not add to a wait step'
      end

      def >>(_other)
        raise 'Can not add to a wait step'
      end
    end

    # simple block step
    class BlockStep < BaseStep
      attr_accessor :conditional, :depends_on, :fields, :key, :label, :prompt

      def list_attributes
        %w[depends_on fields].freeze
      end

      def <<(_other)
        raise 'Can not add to a block step'
      end

      def >>(_other)
        raise 'Can not add to a block step'
      end

      def to_h
        @block = @key
        super
      end
    end

    # input steps are almost the same as block steps (difference is dependency semantics)
    class InputStep < BlockStep
      def to_h
        super.tap do |h|
          h[:input] = h.delete(:block)
        end
      end
    end

    # basic command step
    class CommandStep < BaseStep
      attr_accessor :agents, :artifact_paths, :branches, :concurrency, :concurrency_group,
                    :conditional, :depends_on, :env, :key, :label, :matrix,
                    :plugins, :soft_fail, :timeout_in_minutes

      attr_reader :commands # we define special writers

      def list_attributes
        %w[artifact_paths commands depends_on plugins].freeze
      end

      def hash_attributes
        %w[agents env matrix].freeze
      end

      # only for backwards compatibility
      def key_order
        %i[artifact_paths commands depends_on plugins agents env matrix label key].freeze
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

      def to_h
        @parameters = nil
        @transformer = nil
        @plugins = @plugins.map(&:to_h)

        super
      end

      # add/merge step
      def <<(other)
        # would love to use `case/when` but it does not handle inheritance
        if [BK::Compat::WaitStep, BK::Compat::BlockStep].include?(other.class)
          raise 'Can not add a wait step to another step'
        elsif other.class <= BK::Compat::BaseStep
          merge!(other)
        elsif other.class <= BK::Compat::Plugin
          @plugins << other
        else
          add_commands(*other) unless other.nil?
        end
      end

      # prepend/merge steps
      def >>(other)
        # would love to use `case/when` but it does not handle inheritance
        if [BK::Compat::WaitStep, BK::Compat::BlockStep].include?(other.class)
          raise 'Can not add a wait step to another step'
        elsif other.class <= BK::Compat::BaseStep
          pre_merge!(other)
        elsif other.class <= BK::Compat::Plugin
          @plugins.prepend(other)
        else
          prepend_commands(*other) unless other.nil?
        end
      end

      def merge!(other)
        list_attributes.each { |a| send(a).concat(other.send(a)) }
        hash_attributes.each { |a| send(a).merge!(other.send(a)) }

        update_attributes!(other)
      end

      def pre_merge!(other)
        # almost the same as merge but self/other are reversed here
        list_attributes.each { |a| send("#{a}=", other.send(a).concat(send(a))) }
        hash_attributes.each { |a| send("#{a}=", other.send(a).merge(send(a))) }

        update_attributes!(other)
      end

      def update_attributes!(other)
        @conditional = BK::Compat.xxand(conditional, other.conditional)
        @concurrency = [@concurrency, other.concurrency].compact.min
        @concurrency_group ||= other.concurrency_group
        @branches = "#{@branches} #{other.branches}".strip
        @branches = nil if @branches.empty?
        @timeout_in_minutes = [@timeout_in_minutes, other.timeout_in_minutes].compact.max

        # TODO: these could be a hash with exit codes
        @soft_fail ||= other.soft_fail

        self
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
    class GroupStep < BaseStep
      attr_accessor :depends_on, :key, :label, :steps, :conditional

      def list_attributes
        %w[depends_on steps].freeze
      end

      def initialize(*, **kwargs)
        # ensure label has a ~ default value
        repack = { label: '~' }.merge(kwargs)
        super(*, **repack)
      end

      def to_h
        @group = @label unless @label.nil?
        @label = nil
        @steps = @steps.map(&:to_h)

        super
      end
    end
  end
end
