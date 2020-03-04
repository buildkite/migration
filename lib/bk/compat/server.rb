require "rack"

module BK
  module Compat
    class Server
      def call(env)
        req = Rack::Request.new(env)

        # Make sure the request looks legit
        return [405, {}, []] unless req.post?
        return [404, {}, []] unless req.path == "/"
        return [400, {}, []] if !req.form_data? || !req.params["file"].is_a?(Hash)

        case req.get_header("HTTP_ACCEPT")
        when "application/json"
          format = BK::Compat::Renderer::Format::JSON
          content_type = "application/json"
        when "text/yaml", "", "*/*", nil
          format = BK::Compat::Renderer::Format::YAML
          content_type = "text/yaml"
        else
          return [406, {}, []]
        end

        # Read the file from the request
        contents = req.params["file"][:tempfile].read

        # Figure out which parser to use
        parser_klass = BK::Compat.guess(contents)

        # Parse it and render it as YAML
        begin
          body = parser_klass.new(contents).parse.render(colors: false, format: format)
          [200, { "Content-Type" => content_type }, StringIO.new(body)]
        rescue BK::Compat::Error::NotSupportedError => e
          error_message(500, e.message)
        rescue => e
          error_message(501, "Whoops! You found a bug! Please email keith@buildkite.com with a copy of the file you're trying to convert.")
        end
      end

      private

      def error_message(code, message)
        [code, { "Content-Type" => "text/plain" }, StringIO.new("👎 #{message}\n")]
      end
    end
  end
end
