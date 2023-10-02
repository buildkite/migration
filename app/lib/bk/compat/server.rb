# frozen_string_literal: true

require 'rack'

module BK
  module Compat
    # serve compat tool through HTTP
    class Server
      def call(env)
        req = Rack::Request.new(env)

        # We have only one url at the moment
        return [404, {}, []] if req.path != '/'

        if req.get?
          handle_index(req)
        elsif req.post?
          handle_parse(req)
        else
          [405, {}, []]
        end
      end

      private

      INDEX_HTML_PATH = File.expand_path(File.join(__FILE__, '..', '..', '..', '..', 'public', 'index.html'))

      def handle_index(_req)
        # Read once in production mode, otherwise - read each time.
        html = if ENV['RACK_ENV'] == 'production'
                 @html ||= File.read(INDEX_HTML_PATH)
               else
                 File.read(INDEX_HTML_PATH)
               end

        [200, { 'content-type' => 'text/html' }, StringIO.new(html)]
      end

      def handle_parse(req)
        # Make sure the request looks legit
        return [400, {}, []] if !req.form_data? || !req.params['file'].is_a?(Hash)

        conf = parse_accept(req.get_header('HTTP_ACCEPT'))

        return [406, {}, []] if conf.nil?

        conf[:contents] = req.params['file'][:tempfile].read

        reply(**conf)
      end

      def reply(contents:, format:, content_type:)
        body = BK::Compat.guess(contents).new(contents).parse.render(colors: false, format: format)
        [200, { 'content-type' => content_type }, StringIO.new(body)]
      rescue BK::Compat::Error::NotSupportedError => e
        error_message(500, e.message)
      rescue StandardError
        error_message(
          501,
          [
            'Whoops! You found a bug!',
            'Please email support@buildkite.com about this',
            '(with a copy of the file you are trying to convert if possible).'
          ].join(' ')
        )
      end

      def error_message(code, message)
        [code, { 'content-type' => 'text/plain' }, StringIO.new("👎 #{message}\n")]
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
        end
      end
    end
  end
end
