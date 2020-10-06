require 'spec_helper'
require_relative 'registration/helpers'

RSpec.feature 'GET /export route' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:repository]

  let(:client_data) { attributes_for(:client) }
  let(:exam_data)   { attributes_for(:exam)   }

  it 'returns a CSV with exported data', :no_transaction do
    client_id = repository.clients.insert(clean_client_data(client_data))
    repository.registrations.insert(
      exam_data.merge({ client_id: client_id, registered_at: Time.now }),
    )

    get '/export'

    expect(last_response).to be_ok

    data = last_response.json['csv'].split("\n")

    expect(data[0]).to match(/,requestor_type,.*,email/)
    expect(data[1]).to match(/,"#{exam_data[:requestor_type]}",.*,"#{client_data[:email]}"/)
  end
end
