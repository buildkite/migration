# frozen_string_literal: true

require_relative 'executors'
require_relative 'steps'

module BK
  module Compat
    # CircleCI translation scaffolding
    class CircleCI
      private

      def load_command(name, config)
        raise "Duplicate command name: #{name}" if @commands_by_key.include?(name)

        @commands_by_key[name] = parse_command(name, config)
      end

      def load_job(name, config)
        raise "Duplicate job name: #{name}" if @commands_by_key.include?(name)

        # this may clash commands and jobs
        @commands_by_key[name] = parse_job(name, config)
      end

      def parse_job(name, config)
        # jobs are commands + some additional configs
        parse_command(name, config).tap do |bk_step|
          # TODO: move this logic to executor module
          bk_step >> if config.include?('executor')
                       exc_name = config['executor'].is_a?(Hash) ? config['executor'].keys.first : config['executor']
                       @executors[exc_name] || "# executor #{config['executor']} not supported yet"
                     else
                       parse_executor(**get_executor(config))
                     end

          bk_step.env = config.fetch('environment', {})
        end
      end

      def parse_command(name, config)
        BK::Compat::CircleCIStep.new(key: name).tap do |bk_step|
          translate_steps(config['steps']).each { |step| bk_step << step }
          bk_step.parameters = config.fetch('parameters', {})
        end
      end

      def translate_steps(step_list)
        return [] if step_list.nil?

        step_list.map do |circle_step|
          key, config = string_or_key(circle_step)
          @commands_by_key[key]&.instantiate(config) || translate_step(key, config)
        end
      end
    end
  end
end
