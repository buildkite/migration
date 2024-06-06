# frozen_string_literal: true

require_relative '../../pipeline/step'
require_relative '../../models/plugin'

module BK
  module Compat
    module BitBucketSteps
      # Extend Step translation with services support
      class Step
        def load_services!(global_services)
          @services = []
          composer_config = generate_composer_config(Hash(global_services))

          cmds = [
            '# to user services, add the following composefile to your repository',
            '# and add the image used in the step as `app`',
            "cat > compose.yaml << EOF\n#{composer_config.to_yaml}\nEOF"
          ]

          plugin_config = { 'run' => 'app' }

          @services = BK::Compat::CircleCISteps::CircleCIStep.new(
            key: 'docker compose',
            commands: cmds,
            agents: { 'executor_type' => 'docker_compose' },
            plugins: [
              BK::Compat::Plugin.new(
                name: 'docker-compose',
                config: plugin_config
              )
            ]
          )
        end

        def generate_composer_config(services)
          # TODO: make this less all-encompassing
          containers = { 'app' => { 'depends_on' => services.keys } }
          services.map do |name, conf|
            # TODO: image authentication not translated
            config = conf.slice('image')
            config['resources'] = { 'limits' => { 'memory' => "#{conf['memory']}M" } } if conf.include?('memory')
            config['environment'] = conf['variables'].map { |k, v| "#{k}=#{v}" } if conf.include?('variables')
            containers[name] = config
          end
          { 'services' => containers }
        end

        def translate_services(services)
          return [] if services.nil? || services.empty?

          @services
        end
      end
    end
  end
end
