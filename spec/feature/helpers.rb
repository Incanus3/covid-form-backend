module CovidForm
  module TestHelpers
    module Generic
      def populate_time_slots
        # rubocop:disable Layout/LineLength
        db.time_slots.create_many([
          { name: 'morning 1',   start_time: Utils::Time.today_at(8,  0), end_time: Utils::Time.today_at(10, 0) },
          { name: 'morning 2',   start_time: Utils::Time.today_at(10, 0), end_time: Utils::Time.today_at(12, 0) },
          { name: 'afternoon 1', start_time: Utils::Time.today_at(13, 0), end_time: Utils::Time.today_at(15, 0) },
          { name: 'afternoon 2', start_time: Utils::Time.today_at(15, 0), end_time: Utils::Time.today_at(17, 0) },
        ])
        # rubocop:enable Layout/LineLength
      end
    end
  end
end
