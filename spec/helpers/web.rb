require 'rack/test'

module Rack
  class MockResponse
    def json
      @_json ||= body.empty? ? body : JSON.parse(body)
    end

    def symbolized_json
      case json
      when Hash
        json.deep_symbolize_keys
      when Array
        json.map(&:deep_symbolize_keys)
      else
        raise "cannot symbolize #{json.inspect}"
      end
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

  def put_json(path, body = nil)
    header('Content-Type', 'application/json')
    put(path, body && JSON.generate(body))
  end

  def patch_json(path, body = nil)
    header('Content-Type', 'application/json')
    patch(path, body && JSON.generate(body))
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include JSONRequests

  def app
    CovidForm::Web::App
  end
end
