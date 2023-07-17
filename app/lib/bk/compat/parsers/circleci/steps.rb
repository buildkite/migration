# frozen_string_literal: true

module BK
  module Compat
    # Implementation of step translation
    module CircleCISteps
      def self.translate_run(_config)
        ['# `run` not implemented yet']
      end

      def self.translate_when(_config)
        ['# `when` not implemented yet']
      end

      def self.translate_checkout(*_args)
        ['# No need for checkout, the agent takes care of that']
      end

      def self.translate_setup_remote_docker(_config)
        ['#  No need to setup remote docker, use the host docker']
      end

      def self.translate_save_cache(_config)
        ['# `save_cache` not implemented yet']
      end

      def self.translate_restore_cache(_config)
        ['# `restore_cache` not implemented yet']
      end

      def self.translate_deploy(_config)
        ['# `deploy` not implemented yet (and it has been deprecated)']
      end

      def self.translate_store_artifacts(_config)
        ['# `store_artifacts` not implemented yet']
      end

      def self.translate_store_test_results(_config)
        ['# `store_test_results` has no direct translation (you should try Test Analytics!)']
      end

      def self.translate_persist_to_workspace(_config)
        ['# `persist_to_workspace` not implemented yet']
      end

      def self.translate_attach_workspace(_config)
        ['# `attach_workspace` not implemented yet']
      end

      def self.translate_add_ssh_keys(_config)
        ['# `add_ssh_keys` has no translation, your agent should have the keys to connect where it needs to']
      end

      MAPPING = {
        'run' => method(:translate_run),
        'when' => method(:translate_when),
        'checkout' => method(:translate_checkout),
        'setup-remote-docker' => method(:translate_setup_remote_docker),
        'save-cache' => method(:translate_save_cache),
        'restore-cache' => method(:translate_restore_cache),
        'deploy' => method(:translate_deploy),
        'store-artifacts' => method(:translate_store_artifacts),
        'store-test-results' => method(:translate_store_test_results),
        'persist-to-workspace' => method(:translate_persist_to_workspace),
        'attach-workspace' => method(:translate_attach_workspace),
        'add-ssh-keys' => method(:translate_add_ssh_keys)
      }.freeze
    end
  end
end
