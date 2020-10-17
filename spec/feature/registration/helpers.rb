require 'app/web/validation/contracts'
require 'spec/feature/helpers'

module CovidForm
  module TestHelpers
    module Registration
      include Generic

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
    end
  end
end
