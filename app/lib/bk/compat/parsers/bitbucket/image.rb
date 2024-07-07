# frozen_string_literal: true

require_relative '../../models/plugin'
require_relative '../../models/steps/command'

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
            image_aws_auth(normalized.fetch('aws', {}), name: normalized['name'])
          ].compact.each { |p| cmd << p }

          cmd
        end

        def image_base(conf)
          return nil if conf.empty?

          BK::Compat::Plugin.new(
            name: 'docker',
            config: {
              'image' => conf['name'],
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
              'password-env' => conf['password'].sub(/^\$/, '')
            }
          )
        end

        def image_aws_auth(conf, name: nil)
          return nil if conf.empty?

          # assume the image name is a reference to an ECR repo
          acct, _, _, region, *_rest = name.split('.')

          plugin = {
            'login' => true,
            'account-ids' => acct,
            'region' => region
          }
          plugin['assume-role'] = { 'role-arn' => conf['oidc-role'] } if conf.include?('oidc-role')

          if conf.include?('access-key') || conf.include?('secret-key')
            cmd = [
              '# use AWS_ACCESS_KEY and AWS_SECRET_ACCESS_KEY variables for authentication'
            ]
          end

          BK::Compat::CommandStep.new(
            plugins: [
              BK::Compat::Plugin.new(
                name: 'ecr',
                config: plugin
              )
            ],
            commands: cmd
          )
        end
      end
    end
  end
end
