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

        # Parse it and render it as YAML
        body = BK::Compat::CircleCI.parse_text(contents).render(colors: false, format: format)

        # Yay, return it as YAML
        [200, { "Content-Type" => content_type }, StringIO.new(body)]
      end
    end
  end
end
