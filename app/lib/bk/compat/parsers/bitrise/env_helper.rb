# frozen_string_literal: true

module BK
  module Compat
    class Bitrise
      # Helper methods for processing environment variables in Bitrise configuration
      module EnvHelper
        def self.process_env_variable(env)
          return {} unless env.is_a?(Hash)

          env.delete('opts')

          env
        end

        def self.process_env_variables(vars)
          return {} unless vars.is_a?(Array)

          result = {}
          vars.each do |env|
            result.merge!(process_env_variable(env))
          end
          result
        end
      end
    end
  end
end
