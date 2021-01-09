require 'spec_helper'
require 'spec/feature/helpers'

RSpec.feature 'GET /crud/exam_types route' do
  include CovidForm::Import[:config, :db]
  include CovidForm::TestHelpers::ExamTypes

  before do
    populate_exam_types
  end

  it 'works' do
    get '/crud/exam_types'

    first_exam_type = db.exam_types.first

    expect(last_response).to be_ok
    expect(last_response.symbolized_json).to match({
      status:     'OK',
      exam_types: a_collection_including(
        { id: first_exam_type.id, description: first_exam_type.description },
      ),
    })
  end
end
