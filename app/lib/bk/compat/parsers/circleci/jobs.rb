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
          config['steps'].each do |circle_step|
            bk_step << translate_step(*string_or_key(circle_step))
          end

          if config.include?('executor')
            bk_step << @executors[config['executor']]
          else
            type, exc_conf = get_executor(config)
            bk_step << parse_executor(type, {}, exc_conf) unless type.nil?
          end

          bk_step.env = config.fetch('environment', {})
        end
      end
    end
  end
end
