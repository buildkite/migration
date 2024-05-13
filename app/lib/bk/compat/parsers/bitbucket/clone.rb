# frozen_string_literal: true

require_relative '../../pipeline/step'
require_relative '../../pipeline/plugin'

module BK
  module Compat
    module BitBucketSteps
      # Translatio of clone options
      class Step
        def translate_clone(opts)
          sparse_checkout = opts.delete('sparse-checkout')
          enabled = opts.delete('enabled')
          msg = '# repository interactions (clone options) should be configured in the agent itself'

          # nothing specified
          return [] if sparse_checkout.nil? && enabled.nil? && opts.empty?

          BK::Compat::CommandStep.new(commands: msg).tap do |cmd|
            cmd.env['BUILKITE_REPO'] = '' unless enabled.nil? || enabled
            cmd << sparse_checkout_plugin(sparse_checkout)
          end
        end

        def sparse_checkout_plugin(conf)
          return [] if conf.nil? || !conf.fetch('enabled', true)

          BK::Compat::Plugin.new(
            name: 'sparse-checkout',
            config: {
              'paths' => conf['patterns'],
              'no-cone' => !conf.fetch('cone-mode', true)
            }
          )
        end
      end
    end
  end
end
