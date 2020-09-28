require 'spec_helper'

RSpec.describe 'general' do
  include JSONRequests

  describe 'root route' do
    it 'works' do
      ins_num = '8801019997'

      data = {
        requestor_type:    'PL',
        exam_type:         'PCR',
        exam_date:         '2020-09-28',
        first_name:        'jakub',
        last_name:         'kalab',
        municipality:      'mnicho',
        zip_code:          '251 64',
        email:             'j@k.cz',
        phone_number:      '602222222',
        insurance_number:  ins_num,
        insurance_company: 111
      }

      post_json '/register', data

      expect(last_response).to be_ok
      expect(last_response.json).to eq({ 'status' => 'OK' })

      post_json '/register', data

      expect(last_response).to be_ok
      expect(last_response.json).to eq({
        'status' => 'ERROR',
        'error'  => "client with insurance_number #{ins_num} already exists"
      })
    end
  end
end
