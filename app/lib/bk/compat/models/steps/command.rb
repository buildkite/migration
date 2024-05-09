# frozen_string_literal: true

require_relative 'wait'
require_relative '../plugin'

module BK
  module Compat
    class CommandStep
      attr_accessor :agents, :artifact_paths, :branches, :concurrency, :concurrency_group,
                    :conditional, :depends_on, :env, :key, :label, :matrix, :parameters,
                    :plugins, :soft_fail, :timeout_in_minutes, :transformer

      attr_reader :commands # we define special writers

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
          pre_merge!(other)
        when BK::Compat::Plugin
          @plugins.prepend(other)
        else
          prepend_commands(*other) unless other.nil?
        end
      end

      def merge!(other)
        LIST_ATTRIBUTES.each { |a| send(a).concat(other.send(a)) }
        HASH_ATTRIBUTES.each { |a| send(a).merge!(other.send(a)) }

        update_attributes!(other)
      end

      def pre_merge!(other)
        # almost the same as merge but self/other are reversed here
        LIST_ATTRIBUTES.each { |a| send("#{a}=", other.send(a).concat(send(a))) }
        HASH_ATTRIBUTES.each { |a| send("#{a}=", other.send(a).merge(send(a))) }

        update_attributes!(other)
      end

      def update_attributes!(other)
        @conditional = BK::Compat.xxand(conditional, other.conditional)
        @concurrency = [@concurrency, other.concurrency].compact.min
        @concurrency_group ||= other.concurrency_group
        @branches = "#{@branches} #{other.branches}".strip
        @timeout_in_minutes = [@timeout_in_minutes, other.timeout_in_minutes].compact.max

        # TODO: these could be a hash with exit codes
        @soft_fail ||= other.soft_fail

        self
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
  end
end
