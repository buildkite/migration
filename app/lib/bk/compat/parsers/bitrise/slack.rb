# frozen_string_literal: true

module BK
  module Compat
    module BitriseSteps
      # Handles the translation of slack notifications
      class Translator
        def translate_slack(inputs)
          warnings = generate_warnings(inputs)

          if error_config?(inputs)
            create_dual_notifications(inputs, warnings)
          else
            create_single_notification(inputs, warnings)
          end
        end

        private

        def error_config?(inputs)
          inputs.keys.any? { |k| k.end_with?('_on_error') && !inputs[k].to_s.empty? }
        end

        def generate_warnings(inputs)
          supported_options = %w[
            channel channel_on_error
            text text_on_error
            webhook_url webhook_url_on_error
            emoji emoji_on_error
            from_username from_username_on_error
            color color_on_error
            title title_on_error
            message message_on_error
          ]

          unsupported = inputs.keys.reject { |key| supported_options.include?(key) }
          return nil if unsupported.empty?

          '# Warning: The following options are not supported in Buildkite and will be ignored: ' \
            "#{unsupported.join(', ')}"
        end

        def build_base_config(inputs)
          {
            'channel' => inputs['channel'],
            'message' => inputs['text'],
            'webhook' => inputs['webhook_url']
          }.compact
        end

        def build_error_config(inputs, base_config)
          {
            'channel' => inputs['channel_on_error'] || base_config['channel'],
            'message' => inputs['text_on_error'] || base_config['message'],
            'webhook' => inputs['webhook_url_on_error'] || base_config['webhook']
          }.compact
        end

        def create_single_notification(inputs, warnings)
          BK::Compat::CommandStep.new(
            notify: [{ 'slack' => build_base_config(inputs) }],
            commands: warnings.nil? ? nil : [warnings]
          )
        end

        def create_dual_notifications(inputs, warnings)
          base_config = build_base_config(inputs)
          success_config = base_config.merge('if' => 'build.state == "passed"')
          error_config = build_error_config(inputs, base_config)
                         .merge('if' => 'build.state == "failed"')

          BK::Compat::CommandStep.new(
            notify: [
              { 'slack' => success_config },
              { 'slack' => error_config }
            ],
            commands: warnings.nil? ? nil : [warnings]
          )
        end
      end
    end
  end
end
