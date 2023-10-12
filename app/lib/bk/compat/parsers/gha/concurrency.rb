# frozen_string_literal: true

module BK
  module Compat
    class GitHubActions
      def set_concurrency(bk_step, config)
        group, cancel_in_progress = obtain_concurrency(config['concurrency']) 
        bk_step << ["# `cancel_in_progress` is not supported. Please use Cancel Intermediate Builds."] if cancel_in_progress
        bk_step.concurrency = 1 
        bk_step.concurrency_group = group
      end
  
      def obtain_concurrency(concurrency)
        case concurrency
        when String
          [concurrency, nil]
        when Hash
           concurrency_arr = concurrency.to_a
          group = concurrency_arr.first.last
          cancel_in_progress = concurrency_arr.length == 2 ? concurrency_arr.last.last : nil
          [group, cancel_in_progress]
        end
      end 
    end
  end
end
  