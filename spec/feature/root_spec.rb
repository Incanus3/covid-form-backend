require 'spec_helper'

RSpec.feature 'GET / root route' do
  it 'shows a list of routes' do
    get '/'

    body = last_response.body.downcase

    expect(last_response).to be_ok
    expect(body).to include 'seznam rout'
    expect(body).to include 'post /registration/create'
  end
end
