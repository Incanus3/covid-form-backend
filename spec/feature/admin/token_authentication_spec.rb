require 'spec_helper'
require 'spec/feature/helpers'

RSpec.feature 'JWT token authentication' do # rubocop:disable Metrics/BlockLength
  include CovidForm::Import[:db, :config]
  include CovidForm::TestHelpers::Authentication

  let(:email)    { 'admin@test.cz' }
  let(:password) { 'password'      }

  before do
    populate_account_statuses
    create_admin_account(email, password)
  end

  describe 'login route' do
    context 'with correct credentials' do
      it 'returns success response with access and refresh tokens' do
        post_json '/auth/login', email: email, password: password

        expect(last_response).to be_ok
        expect(last_response.json['success']).to eq 'You have been logged in'
        expect(last_response.json).to have_key('access_token')
        expect(last_response.json).to have_key('refresh_token')
      end
    end

    context 'with bad email' do
      it 'returns an appropriate error response' do
        post_json '/auth/login', email: 'bad', password: password

        expect(last_response).to be_unauthorized
        expect(last_response.json['error']      ).to eq 'There was an error logging in'
        expect(last_response.json['field-error']).to eq ['email', 'no matching login']
      end
    end

    context 'with bad password' do
      it 'returns an appropriate error response' do
        post_json '/auth/login', email: email, password: 'bad'

        expect(last_response).to be_unauthorized
        expect(last_response.json['error']      ).to eq 'There was an error logging in'
        expect(last_response.json['field-error']).to eq ['password', 'invalid password']
      end
    end

    context 'with missing fields' do
      it 'returns an appropriate error response' do
        post_json '/auth/login'

        expect(last_response).to be_unauthorized
        expect(last_response.json['error']      ).to eq 'There was an error logging in'
        expect(last_response.json['field-error']).to eq ['email', 'no matching login']
      end
    end
  end

  describe 'accessing route requiring authentication' do
    context 'without authentication' do
      it 'returns an appropriate error response' do
        get '/admin/export'

        expect(last_response).to be_unauthorized
        expect(last_response.json['error']).to eq 'Please login to continue'
      end
    end

    context 'with expired token' do
      it 'returns an appropriate error response' do
        log_in_admin

        Timecop.freeze(Time.now + config[:auth][:access_token_lifetime_minutes] * 60) do
          get '/admin/export'

          expect(last_response).to be_unauthorized
          expect(last_response.json['error']).to eq 'expired JWT access token'
        end
      end
    end

    context 'with malformed authentication header' do
      it 'returns an appropriate error response' do
        header 'Authorization', 'bad'
        get    '/admin/export'

        expect(last_response).to be_unauthorized
        expect(last_response.json['error'])
          .to eq 'invalid JWT format or claim in Authorization header'
      end
    end

    context 'with correct authentication' do
      it 'lets user access the endpoint' do
        log_in_admin

        get '/admin/export'

        expect(last_response).to be_ok
      end
    end
  end

  describe 'refreshing tokens' do
    it 'works' do
      post_json '/auth/login', email: email, password: password

      access_token, refresh_token = last_response.json.values_at('access_token', 'refresh_token')

      Timecop.freeze(Time.now + config[:auth][:access_token_lifetime_minutes] * 60) do
        header 'Authorization', access_token
        get    '/admin/export'

        expect(last_response).to be_unauthorized
        expect(last_response.json['error']).to eq 'expired JWT access token'

        header    'Authorization',       access_token
        post_json '/auth/refresh_token', refresh_token: refresh_token

        access_token = last_response.json['access_token']

        header 'Authorization', access_token
        get    '/admin/export'

        expect(last_response).to be_ok
      end
    end

    it 'requires access token to be provided' do
      post_json '/auth/login', email: email, password: password

      refresh_token = last_response.json['refresh_token']

      header    'Authorization',       nil
      post_json '/auth/refresh_token', refresh_token: refresh_token

      expect(last_response).to be_unauthorized
      expect(last_response.json['error']).to eq 'no JWT access token provided during refresh'
    end

    # we can't test this because refresh token deadline is computed in the database using
    # CURRENT_TIMESTAMP, which we can't override
    # context 'with expired refresh token' do
    #   it 'returns an appropriate error response', skip: "can't test"
    # end
  end
end
