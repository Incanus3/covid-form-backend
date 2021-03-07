require 'ostruct'
require 'app/dependencies'

module CovidForm
  module Services
    class Configuration
      include Import[:config]

      def allowed_exam_dates
        OpenStruct.new(
          start_date: start_of_this_week + config.open_registration_in_weeks  * 7,
          end_date:   end_of_this_week   + config.close_registration_in_weeks * 7,
        )
      end

      private

      def start_of_this_week
        date  = Date.today
        date -= 1 until date.wday == config.week_starts_on
        date
      end

      def end_of_this_week
        start_of_this_week + 6
      end
    end
  end
end
