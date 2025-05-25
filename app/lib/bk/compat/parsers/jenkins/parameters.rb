# frozen_string_literal: true

require_relative '../../models/steps/input'

module BK
  module Compat
    # Jenkins YAML converter
    class Jenkins
      # TODO: use an actual parser instead of regex
      PARAM_REGEXP = /\A
        (?<type>\w+)  # type of the parameter
        \(            # Opening parenthesis
          (?:
            \s*
            (?:
              name:\s*['"](?<name>[^'"]+)['"]
            | description:\s*['"](?<description>[^'"]+)['"]
            | defaultValue:\s*['"]?(?<defaultValue>[^'",)]*)['"]?
            | choices:\s*\[(?<choices>[^\]]+)\]
            )
            \s*
            ,?
          )+
        \)
      \Z/x

      private

      def translate_parameters(parameters)
        return [] unless parameters.is_a?(Array)

        InputStep.new(
          key: 'parameters',
          fields: parse_parameters(parameters)
        )
      end

      def parse_parameters(parameters)
        parameters.map do |parameter|
          PARAM_REGEXP.match(parameter) do |match|
            param_data = match.named_captures.transform_values do |value|
              value.strip if value.is_a?(String)
            end
            type = param_data.delete('type')
            send("translate_parameter_#{type}", param_data)
          end
        end
      end

      def translate_parameter_string(data)
        {
          text: data['name'],
          key: data['name'],
          hint: data['description'],
          default: data['defaultValue']
        }
      end
      alias translate_parameter_password translate_parameter_string
      alias translate_parameter_text translate_parameter_string

      def translate_parameter_boolean(data)
        {
          select: data['name'],
          key: data['name'],
          hint: data['description'],
          default: data['defaultValue'],
          options: [
            { label: 'true', value: true },
            { label: 'false', value: false }
          ]
        }
      end

      def translate_parameter_choice(data)
        {
          select: data['name'],
          key: data['name'],
          hint: data['description'],
          default: data['defaultValue'],
          # split/strip/gsub because of lack of a real parser
          options: data['choices'].split(',').map do |choice|
            val = choice.strip.gsub(/^\A['"]|['"]\Z/, '')
            { label: val, value: val }
          end
        }
      end
    end
  end
end
