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
    end
  end
end
