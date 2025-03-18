# frozen_string_literal: true

require_relative 'base'
require_relative 'block'
require_relative 'wait'
require_relative '../plugin'
require_relative 'command_helpers'

module BK
  module Compat
    # basic command step
    class CommandStep < BaseStep
      include CommandHelpers

      attr_accessor :agents, :artifact_paths, :branches, :concurrency, :concurrency_group,
                    :conditional, :depends_on, :env, :key, :label, :matrix, :notify,
                    :parallelism, :plugins, :soft_fail, :timeout_in_minutes

      attr_reader :commands # we define special writers

      def list_attributes
        %w[artifact_paths commands depends_on notify plugins].freeze
      end

      def hash_attributes
        %w[agents env matrix].freeze
      end

      # attributes merged with the minimum value
      def min_attributes
        %w[concurrency parallelism].freeze
      end

      # only for backwards compatibility
      def key_order
        %i[artifact_paths commands depends_on plugins agents env matrix label key concurrency].freeze
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

      # Sets the stack value for agents
      # @param stack_value [String] the stack value to set
      def stack=(stack_value)
        @agents ||= {}
        @agents[:stack] = stack_value if stack_value
      end

      # Updates agent targeting configuration
      # @param targeting [Hash] targeting configuration
      def agent_targeting=(targeting)
        return unless targeting

        @agents ||= {}

        return unless targeting['stack']

        @agents[:stack] = targeting['stack']
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
        @concurrency_group ||= other.concurrency_group
        @branches = "#{@branches} #{other.branches}".strip
        @timeout_in_minutes = [@timeout_in_minutes, other.timeout_in_minutes].compact.max
        min_attributes.each { |a| assign_minimum(a, other) }

        # TODO: these could be a hash with exit codes
        @soft_fail ||= other.soft_fail

        self
      end

      def assign_minimum(key, other)
        send("#{key}=", [send(key), other.send(key)].compact.min)
      end
    end
  end
end
