require "rack/oauth2"

module RspecApiDocumentation
  class OAuth2MACClient < ClientBase
    include WebMock::API
    attr_accessor :last_response, :last_request
    private :last_response, :last_request

    def request_headers
      env_to_headers(last_request.env)
    end

    def response_headers
      last_response.headers
    end

    def query_string
      last_request.env["QUERY_STRING"]
    end

    def status
      last_response.status
    end

    def response_body
      last_response.body
    end

    def content_type
      last_request.content_type
    end

    protected

    def do_request(method, path, params)
      self.last_response = access_token.send(method, "http://example.com#{path}", :body => params, :header => headers(method, path, params))
    end

    class ProxyApp < Struct.new(:client, :app)
      def call(env)
        client.last_request = Struct.new(:env, :content_type).new(env, env["CONTENT_TYPE"])
        app.call(env.merge("SCRIPT_NAME" => ""))
      end
    end

    def access_token
      @access_token ||= begin
                          app = ProxyApp.new(self, context.app)
                          stub_request(:any, %r{http://example\.com}).to_rack(app)
                          Rack::OAuth2::Client.new(options.merge(:host => "example.com", :scheme => "http")).access_token!
                        end
    end
  end
end
