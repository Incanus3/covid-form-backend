require 'spec_helper'
require 'spec/feature/registration/helpers'
require 'scripts/send_capacity_report'

RSpec.feature 'send_capacity_report script' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:config, :db]

  subject(:reporter) { CovidForm::Reporter.new }

  let(:full_date)                { Date.today + 1 }
  let(:closed_date)              { Date.today + 2 }
  let(:daily_registration_limit) { 240            }

  before do
    populate_exam_types
    populate_time_slots
    populate_time_slot_exam_types

    mock_config_with(daily_registration_limit:        daily_registration_limit,
                     allow_registration_for_weekends: false)

    db.daily_overrides.create(date: closed_date, registration_limit: 0)

    first_slot = time_slots_with_name('morning 1').one!
    last_slot  = time_slots_with_name('afternoon 2').one!

    create_many_clients_with_registrations(
      30,
      exam_overrides: { exam_date: full_date, exam_type: 'pcr', time_slot_id: first_slot.id },
    )
    create_many_clients_with_registrations(
      30,
      exam_overrides: { exam_date: full_date, exam_type: 'ag', time_slot_id: first_slot.id },
    )
    create_many_clients_with_registrations(
      20,
      exam_overrides: { exam_date: full_date, exam_type: 'ag', time_slot_id: last_slot.id },
    )
  end

  it 'works' do
    reporter.send_report(number_of_days: 7)
  end
end
