module CovidForm
  module Web
    class Authentication
      include Dry::Monads[:result]
      include Import[:config]

      class FailureWithoutArgs < Failure
        def initialize
          super(nil)
        end
      end

      MissingAuthorizationHeader       = Class.new(FailureWithoutArgs)
      MalformedAuthorizationHeader     = Class.new(FailureWithoutArgs)
      UnrecognizedAuthenticationMethod = Class.new(Failure)
      BadCredentials                   = Class.new(FailureWithoutArgs)

      attr_private_initialize [:config, :request]

      def perform
        auth_header = request.headers['authorization']

        return MissingAuthorizationHeader.new unless auth_header

        method, payload = auth_header.split

        return MalformedAuthorizationHeader.new unless method && payload
        return UnrecognizedAuthenticationMethod.new(method) unless method.casecmp('password').zero?
        return BadCredentials.new unless payload == self.config[:auth][:admin_password]

        Success.new(nil)
      end
    end
  end
end
