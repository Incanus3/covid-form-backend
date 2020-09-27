require 'spec_helper'

RSpec.describe 'general' do
  include JSONRequests

  describe 'root route' do
    it 'works' do
      post_json '/register', {
        requestor_type:    'PL',
        exam_type:         'PCR',
        exam_date:         '2020-09-28',
        first_name:        'jakub',
        last_name:         'kalab',
        municipality:      'mnicho',
        zip_code:          '251 64',
        email:             'j@k.cz',
        phone_number:      '602222222',
        insurance_number:  '8801019997',
        insurance_company: 111
      }

      pp last_response.json

      expect(last_response).to be_ok
      expect(last_response.json).to eq({ 'result' => 'OK' })
    end
  end
end
