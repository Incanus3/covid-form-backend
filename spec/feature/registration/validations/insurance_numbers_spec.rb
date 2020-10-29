require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'POST /register route - insurance number validations' do # rubocop:disable Metrics/BlockLength
  include CovidForm::TestHelpers::Generic
  include CovidForm::Import[:db]

  let(:insurance_company) { 111                                 }
  let(:insurance_number ) { raise 'must be provided by context' }

  let(:client_data      ) {
    attributes_for(:client,
                   insurance_number:  insurance_number,
                   insurance_company: insurance_company)
  }
  let(:exam_data        ) { attributes_for(:exam)                    }
  let(:request_data     ) { { client: client_data, exam: exam_data } }

  before do
    mock_config_with(
      allow_registration_for_weekends:       true,
      allow_registration_for_today_after_10: true,
    )

    populate_time_slots
  end

  shared_examples('common IN validations') do |number_of_digits:|
    context 'when it contains non-numbers' do
      let(:insurance_number) { 'abcdefghij'[...number_of_digits] }

      it 'request is rejected' do
        post_json '/register', request_data

        response_data = last_response.symbolized_json

        expect(last_response).to be_unprocessable
        expect(response_data[:status]).to eq 'ERROR'
        expect(response_data[:client][:insurance_number])
          .to include 'must only contain numbers'
      end
    end

    context 'when month is not valid' do
      let(:insurance_number) { '5013011234'[...number_of_digits] }

      it 'request is rejected' do
        post_json '/register', request_data

        response_data = last_response.symbolized_json

        expect(last_response).to be_unprocessable
        expect(response_data[:status]).to eq 'ERROR'
        expect(response_data[:client][:insurance_number])
          .to include '13 is not a valid month'
      end
    end

    context 'when day is not valid' do
      let(:insurance_number) { '5001321237'[...number_of_digits] }

      it 'request is rejected' do
        post_json '/register', request_data

        response_data = last_response.symbolized_json

        expect(last_response).to be_unprocessable
        expect(response_data[:status]).to eq 'ERROR'
        expect(response_data[:client][:insurance_number])
          .to include '32 is not a valid day of month January'
      end
    end

    context 'when it is EČP' do
      context 'when it is otherwise valid' do
        let(:insurance_number) { '5001419874'[...number_of_digits] }

        it 'request is accepted' do
          post_json '/register', request_data

          expect(last_response).to be_ok
        end
      end

      context 'when it also RČ+' do
        let(:insurance_number) { '5021419876'[...number_of_digits] }

        it 'request is rejected' do
          post_json '/register', request_data

          response_data = last_response.symbolized_json

          expect(last_response).to be_unprocessable
          expect(response_data[:status]).to eq 'ERROR'
          expect(response_data[:client][:insurance_number])
            .to include 'must not be both RČ+ and EČP'
        end
      end

      context 'when suffix is lower then 600(0)' do
        let(:insurance_number) { '5001411239'[...number_of_digits] }

        it 'request is rejected' do
          post_json '/register', request_data

          response_data = last_response.symbolized_json

          expect(last_response).to be_unprocessable
          expect(response_data[:status]).to eq 'ERROR'
          expect(response_data[:client][:insurance_number])
            .to include a_string_matching('must not end with 123')
        end
      end
    end
  end

  context 'with 9-digit IN' do
    context 'when valid' do
      let(:insurance_number) { '500101123' }

      it 'request is accepted' do
        post_json '/register', request_data

        expect(last_response).to be_ok
      end
    end

    context 'when it ends with 000' do
      let(:insurance_number) { '500101000' }

      it 'request is rejected' do
        post_json '/register', request_data

        response_data = last_response.symbolized_json

        expect(last_response).to be_unprocessable
        expect(response_data[:status]).to eq 'ERROR'
        expect(response_data[:client][:insurance_number]).to include 'must not end with 000'
      end
    end

    context 'when year part is higher than 53' do
      let(:insurance_number) { '550101123' }

      it 'request is rejected' do
        post_json '/register', request_data

        response_data = last_response.symbolized_json

        expect(last_response).to be_unprocessable
        expect(response_data[:status]).to eq 'ERROR'
        expect(response_data[:client][:insurance_number])
          .to include 'birth year must not be before 1900'
      end
    end

    include_examples 'common IN validations', number_of_digits: 9
  end

  context 'with 10-digit IN' do
    context 'when valid' do
      let(:insurance_number) { '5501011230' }

      it 'request is accepted' do
        post_json '/register', request_data

        expect(last_response).to be_ok
      end
    end

    context 'when not divisible by 11' do
      let(:insurance_number) { '5501011231' }

      it 'request is rejected' do
        post_json '/register', request_data

        response_data = last_response.symbolized_json

        expect(last_response).to be_unprocessable
        expect(response_data[:status]).to eq 'ERROR'
        expect(response_data[:client][:insurance_number]).to include 'must be divisible by 11'
      end
    end

    include_examples 'common IN validations', number_of_digits: 10
  end

  context 'with IN shorter then 9 digits' do
    let(:insurance_number) { '12345678' }

    it 'request is rejected' do
      post_json '/register', request_data

      response_data = last_response.symbolized_json

      expect(last_response).to be_unprocessable
      expect(response_data[:status]).to eq 'ERROR'
      expect(response_data[:client][:insurance_number])
        .to include 'must not be shorter than 9 characters'
    end
  end

  context 'with IN longer then 10 digits' do
    let(:insurance_number) { '12345678901' }

    it 'request is rejected' do
      post_json '/register', request_data

      response_data = last_response.symbolized_json

      expect(last_response).to be_unprocessable
      expect(response_data[:status]).to eq 'ERROR'
      expect(response_data[:client][:insurance_number])
        .to include 'must not be longer than 10 characters'
    end
  end

  context 'for a foreign patient' do
    let(:insurance_company) { 999         }
    let(:insurance_number)  { '743277000' }

    it 'any insurance number is accepted' do
      post_json '/register', request_data

      expect(last_response).to be_ok
    end
  end
end
