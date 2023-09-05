# frozen_string_literal: true

module BK
  module Compat
    # CircleCI translation scaffolding
    class CircleCI
      private

      def parse_job(key, config)
        bk_step = BK::Compat::CommandStep.new(key: key, label: ":circleci: #{key}")

        config.fetch('steps').each do |circle_step|
          bk_step << transform_circle_step_to_commands(circle_step)
        end

        setup_docker_executor(bk_step, config.fetch('docker', []))
        bk_step.env = config.fetch('environment', {})
        @steps_by_key[key] = bk_step
      end
    end
  end
end
