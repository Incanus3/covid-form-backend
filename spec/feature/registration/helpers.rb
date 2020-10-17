require 'app/web/validation/contracts'

module CovidForm
  module TestHelpers
    module Registration
      def clean_client_data(data)
        CovidForm::Web::Validation::ClientSchema.call(data).to_h
      end

      def serialize(entity)
        entity.to_h.transform_values { |val| val.is_a?(Date) ? val.to_s : val }
      end

      def create_client_with_registration(
        client_data: attributes_for(:client), exam_data: attributes_for(:exam)
      )
        client = db.clients.create(clean_client_data(client_data))
        db.registrations.create_for_client(exam_data, client)
      end

      def create_many_clients_with_registrations(count, exam_overrides: {})
        client_records = db.clients.create_many(
          attributes_for_list(:client, count).map { clean_client_data(_1) },
        )

        # rubocop:disable Performance/ChainArrayAllocation
        db.registrations.create_many(client_records
          .zip(attributes_for_list(:exam, count, **exam_overrides))
          .map { |(client_record, exam_attrs)|
            exam_attrs.merge(client_id: client_record[:id], registered_at: Time.now)
          })
        # rubocop:enable Performance/ChainArrayAllocation
      end

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
