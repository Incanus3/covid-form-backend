module CovidForm
  class RegistrationResultSerializer
    def self.serialize(result)
      if result.success?
        { status: 'OK' }
      else
        { status: 'ERROR', error: result.failure }
      end
    end
  end
end
