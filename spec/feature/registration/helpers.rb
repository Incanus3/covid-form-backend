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

      def create_client_with_registration(client_data: attributes_for(:client),
                                          exam_data:   attributes_for(:exam))
        client_id = repository.clients.insert(clean_client_data(client_data))
        repository.registrations.insert(
          exam_data.merge({ client_id: client_id, registered_at: Time.now }),
        )
      end

      def create_many_clients_with_registrations(count, exam_overrides: {})
        client_records = repository.clients.dataset.returning.multi_insert(
          attributes_for_list(:client, count).map { clean_client_data(_1) },
        )

        # rubocop:disable Performance/ChainArrayAllocation
        repository.registrations.multi_insert(client_records
          .zip(attributes_for_list(:exam, count, **exam_overrides))
          .map { |(client_record, exam_attrs)|
            exam_attrs.merge(client_id: client_record[:id], registered_at: Time.now)
          })
        # rubocop:enable Performance/ChainArrayAllocation
      end
    end
  end
end
