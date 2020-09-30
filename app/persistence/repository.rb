module CovidForm
  module Persistence
    class Repository
      # TODO: make this generic
      def clients
        require_relative 'models'

        Clients
      end
    end
  end
end
