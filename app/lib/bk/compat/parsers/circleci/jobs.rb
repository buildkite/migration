# frozen_string_literal: true

require_relative 'executors'

module BK
  module Compat
    # CircleCI translation scaffolding
    class CircleCI
      private

      def load_job(name, config)
        raise "Duplicate job name: #{name}" if @steps_by_key.include?(name)

        @steps_by_key[name] = parse_job(name, config)
      end

      def parse_job(name, config)
        BK::Compat::CommandStep.new(key: name, label: ":circleci: #{name}").tap do |bk_step|
          bk_step << parse_steps(config['steps'])

          bk_step << if config.include?('executor')
                       @executors[config['executor']]
                     else
                       parse_executor(**get_executor(config))
                     end

          bk_step.env = config.fetch('environment', {})
        end
      end

      def parse_steps(step_list)
        return [] if step_list.nil?

        step_list.map do |circle_step|
          translate_step(*string_or_key(circle_step))
        end
      end
    end
  end
end
