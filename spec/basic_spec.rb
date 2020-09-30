require 'spec_helper'
require 'app/application'

RSpec.describe 'general' do
  describe 'root route' do
    it 'works' do
      client_data = attributes_for(:client)
      exam_data   = attributes_for(:exam)
      data        = client_data.merge(exam_data)

      pp client_data
      pp exam_data

      post_json '/register', data

      pp last_response.json

      expect(last_response     ).to be_ok
      expect(last_response.json).to eq({ 'status' => 'OK' })

      post_json '/register', data

      expect(last_response     ).to be_ok
      expect(last_response.json).to eq({
        'status' => 'ERROR',
        'error'  => "client with insurance_number #{client_data[:insurance_number]} already exists"
      })
    end
  end
end
