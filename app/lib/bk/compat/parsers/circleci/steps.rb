# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Implementation of native step translation
      class Builtins
        def register
          [
            %w[
              add-ssh-keys
              attach-workspace
              checkout
              deploy
              persist-to-workspace
              restore-cache
              run
              save-cache
              setup-remote-docker
              store-artifacts
              store-test-results
              when
            ].freeze,
            method(:translator)
          ]
        end

        private

        def translator(action, config)
          send("translate_#{action.gsub('-', '_')}", config)
        end

        def translate_run(_config)
          # TODO
          ['# `run` not implemented yet']
        end

        def translate_when(_config)
          # TODO
          ['# `when` not implemented yet']
        end

        def translate_checkout(*_args)
          ['# No need for checkout, the agent takes care of that']
        end

        def translate_setup_remote_docker(_config)
          ['#  No need to setup remote docker, use the host docker']
        end

        def translate_save_cache(_config)
          # TODO
          ['# `save_cache` not implemented yet']
        end

        def translate_restore_cache(_config)
          # TODO
          ['# `restore_cache` not implemented yet']
        end

        def translate_deploy(_config)
          # TODO
          ['# `deploy` not implemented yet (and it has been deprecated)']
        end

        def translate_store_artifacts(_config)
          # TODO
          ['# `store_artifacts` not implemented yet']
        end

        def translate_store_test_results(_config)
          # TODO
          ['# `store_test_results` has no direct translation (you should try Test Analytics!)']
        end

        def translate_persist_to_workspace(_config)
          # TODO
          ['# `persist_to_workspace` not implemented yet']
        end

        def translate_attach_workspace(_config)
          # TODO
          ['# `attach_workspace` not implemented yet']
        end

        def translate_add_ssh_keys(_config)
          # TODO
          ['# `add_ssh_keys` has no translation, your agent should have the keys to connect where it needs to']
        end
      end
    end
  end
end
