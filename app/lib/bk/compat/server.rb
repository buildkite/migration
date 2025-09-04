# frozen_string_literal: true

require 'rack'

module BK
  module Compat
    # serve compat tool through HTTP
    class Server
      def call(env)
        req = Rack::Request.new(env)

        # We have only one url at the moment
        return error_message('Not found', code: 404) if req.path != '/'

        if req.get?
          handle_index(req)
        elsif req.post?
          handle_parse(req)
        else
          error_message('Invalid request', code: 405)
        end
      end

      INDEX_HTML_PATH = File.expand_path(File.join(__FILE__, '..', '..', '..', '..', 'public', 'index.html'))

      private

      def handle_index(_req)
        # Read once in production mode, otherwise - read each time.
        html = if ENV['RACK_ENV'] == 'production'
                 @html ||= File.read(INDEX_HTML_PATH)
               else
                 File.read(INDEX_HTML_PATH)
               end

        success_message(html, content_type: 'text/html')
      end

      def handle_parse(req)
        # Make sure the request looks legit
        return error_message('Invalid request', code: 400) if !req.form_data? || !req.params['file'].is_a?(Hash)

        conf = parse_accept(req.get_header('HTTP_ACCEPT'))
        return conf unless conf.is_a?(Hash)

        conf[:contents] = req.params['file'][:tempfile].read

        reply(**conf)
      end

      def reply(contents:, format:, content_type:)
        parser = find_parser(contents)
        return parser if parser.is_a?(Array) # Error response

        body = parser.new(contents).parse.render(colors: false, format: format)
        success_message(body, content_type: content_type)
      rescue BK::Compat::Error::ParseError => e
        error_message(e.message, code: 501)
      rescue StandardError
        error_message(
          [
            'Whoops! You found a bug!',
            'Please open an issue in the GH repo with a copy of the file you are trying to convert if possible.',
            'Otherwise email support@buildkite.com about this with the file attached.'
          ].join(' ')
        )
      end

      def find_parser(contents)
        parser = BK::Compat.guess(contents)
        return parser unless parser.nil?

        # Try to detect if it's a YAML syntax error
        BK::Compat::Error::CompatError.safe_yaml do
          YAML.safe_load(contents)
          return error_message(
            [
              'Parser could not be identified.',
              'Please ensure your file is valid YAML for a supported CI platform',
              '(GitHub Actions, CircleCI, Jenkins, Bitbucket, Bitrise, or Harness).'
            ]
          )
        end
      end

      def error_message(message, code: 500)
        [code, { 'content-type' => 'text/plain' }, StringIO.new("👎 ERROR 👎\n#{message}\n")]
      end

      def success_message(message, content_type: 'text/plain')
        [200, { 'content-type' => content_type }, StringIO.new(message)]
      end

      def parse_accept(accept_header)
        case accept_header
        when 'application/json'
          {
            format: BK::Compat::Renderer::Format::JSON,
            content_type: 'application/json'
          }
        when 'text/yaml', '', '*/*', nil
          {
            format: BK::Compat::Renderer::Format::YAML,
            content_type: 'text/yaml'
          }
        else
          error_message('Invalid request', code: 406) if conf.nil?
        end
      end
    end
  end
end
