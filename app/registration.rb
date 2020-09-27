require 'app/db'

module CovidForm
  class Registration
    def self.perform(data)
      puts 'in Registration.perform'
      pp data

      'OK'
    end
  end
end
