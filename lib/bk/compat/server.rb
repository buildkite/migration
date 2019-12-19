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

        # Read the file from the request
        contents = req.params["file"][:tempfile].read

        # Parse it and render it as YAML
        body = BK::Compat::CircleCI.parse_text(contents).render

        # Yay, return it as YAML
        [200, { "Content-Type" => "text/yaml" }, StringIO.new(body)]
      end
    end
  end
end
