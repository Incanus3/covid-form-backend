require 'spec_helper'

RSpec.feature 'GET /export route' do
  context 'without authentication' do
    it 'returns an appropriate error response' do
      get '/export'

      expect(last_response).to be_unauthorized
      expect(last_response.json['error'])
        .to eq 'authentication failed: missing Authorization header'
    end
  end

  context 'with malformed authentication header' do
    it 'returns an appropriate error response' do
      header 'Authorization', 'XXX'
      get    '/export'

      expect(last_response).to be_unauthorized
      expect(last_response.json['error'])
        .to eq 'authentication failed: malformed Authorization header'
    end
  end

  context 'with unrecognized authentication method' do
    it 'returns an appropriate error response' do
      header 'Authorization', 'MagicToken XXX'
      get    '/export'

      expect(last_response).to be_unauthorized
      expect(last_response.json['error'])
        .to eq "authentication failed: unrecognized authentication method 'MagicToken'"
    end
  end

  context 'with bad password' do
    it 'returns an appropriate error response' do
      header 'Authorization', 'Password XXX'
      get    '/export'

      expect(last_response).to be_unauthorized
      expect(last_response.json['error']).to eq 'authentication failed: bad credentials'
    end
  end
end
