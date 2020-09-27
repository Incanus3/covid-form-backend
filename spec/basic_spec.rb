require 'spec_helper'

RSpec.describe 'general' do
  include JSONRequests

  describe 'root route' do
    it 'works' do
      post '/register'

      expect(last_response).to be_ok
      expect(last_response.json).to eq({ 'result' => 'OK' })
    end
  end
end
