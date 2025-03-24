# frozen_string_literal: true

module BK
  module Compat
    class Bitrise
      # Helper methods for processing environment variables in Bitrise configuration
      module EnvHelper
        def self.process_env_variable(env, target_env)
          return unless env.is_a?(Hash)

          env.each do |key, value|
            next if key == 'opts' || key.to_s.strip.empty? || value.to_s.strip.empty?

            target_env[key] = value
          end
        end

        def self.process_env_variables(vars, target_env)
          return unless vars.is_a?(Array)

          vars.each do |env|
            process_env_variable(env, target_env)
          end
        end
      end
    end
  end
end
