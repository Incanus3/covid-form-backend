require 'rack/test'

module Rack
  class MockResponse
    def json
      body.empty? ? body : JSON.parse(body)
    end

    def symbolized_json
      json.deep_symbolize_keys
    end

    def conflict?
      status == 409
    end
  end
end

module JSONRequests
  def post_json(path, body = nil)
    header('Content-Type', 'application/json')
    post(path, body && JSON.generate(body))
  end

  def patch_json(path, body = nil)
    header('Content-Type', 'application/json')
    patch(path, body && JSON.generate(body))
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include JSONRequests
end
