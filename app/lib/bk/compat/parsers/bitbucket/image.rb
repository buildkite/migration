# frozen_string_literal: true

module BK
  module Compat
    module BitBucketSteps
      # Implementation of image-related key translations
      class Step
        def translate_image(image)
          return [] if image.nil?

          normalized = image.is_a?(String) ? { 'name' => image } : image

          cmd = BK::Compat::CommandStep.new

          [
            image_base(normalized.slice('name', 'run-as-user')),
            image_basic_auth(normalized.slice('password', 'username')),
            image_aws_auth(normalized.fetch('aws', {}))
          ].compact.each { |p| cmd << p }

          cmd
        end

        def image_base(conf)
          return nil if conf.empty?

          BK::Compat::Plugin.new(
            name: 'docker',
            config: {
              'image' => conf.delete('name'),
              'user' => conf.delete('run-as-user')
            }.compact
          )
        end

        def image_basic_auth(conf)
          return nil if conf.empty?

          BK::Compat::Plugin.new(
            name: 'docker-login',
            config: {
              'username' => conf['username'],
              'password-env' => conf['password'].ltrim('$')
            }
          )
        end

        def image_aws_auth(conf)
          return nil if conf.empty?

          plugin = {
            'login' => true,
            'account-ids' => '$AWS_ACCOUNT',
            'region' => '$AWS_DEFAULT_REGION'
          }
          plugin['assume-role'] = { 'role-arn' => config['oidc-role'] } if config.include?('oidc-role')

          BK::Compat::Plugin.new(
            name: 'ecr',
            config: plugin
          )
        end
      end
    end
  end
end
