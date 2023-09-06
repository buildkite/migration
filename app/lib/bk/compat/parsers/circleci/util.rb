# frozen_string_literal: true

module BK
  module Compat
    # CircleCI translation of workflows
    class CircleCI
      private

      def string_or_key(job)
        case job
        when String
          key = job
          config = {}
        when Hash
          key = job.keys.first
          config = job[key]
        else
          raise "Job is not a hash or string! What could #{job.inspect} be!?"
        end
        [key, config]
      end
    end
  end
end
