require 'spec_helper'
require 'webmock/rspec'
require 'spec/feature/registration/helpers'
require 'scripts/send_capacity_report'

# rubocop:disable Metrics/BlockLength, RSpec/ExampleLength, RSpec/MultipleMemoizedHelpers
RSpec.feature 'send_capacity_report script' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:config, :db]

  let(:open_date)                { Date.today + 1 }
  let(:closed_date)              { Date.today + 2 }
  let(:daily_registration_limit) { 240            }
  let(:number_of_days)           { 7              }

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
      exam_overrides: { exam_date: open_date, exam_type: 'pcr', time_slot_id: first_slot.id },
    )
    create_many_clients_with_registrations(
      30,
      exam_overrides: { exam_date: open_date, exam_type: 'ag', time_slot_id: first_slot.id },
    )
    create_many_clients_with_registrations(
      20,
      exam_overrides: { exam_date: open_date, exam_type: 'ag', time_slot_id: last_slot.id },
    )
  end

  let(:total_coef_sum)   { db.time_slots.all.sum(&:limit_coefficient)                    }

  let(:ag_exam_type)     { db.exam_types.root.where(id: 'ag').combine(:time_slots).one!  }
  let(:ag_coef_sum)      { ag_exam_type.time_slots.sum(&:limit_coefficient)              }
  let(:ag_max_capacity)  { daily_registration_limit * ag_coef_sum / total_coef_sum       }

  let(:pcr_exam_type)    { db.exam_types.root.where(id: 'pcr').combine(:time_slots).one! }
  let(:pcr_coef_sum)     { pcr_exam_type.time_slots.sum(&:limit_coefficient)             }
  let(:pcr_max_capacity) { daily_registration_limit * pcr_coef_sum / total_coef_sum      }

  let(:registrations_for_ag_slots) {
    db.registrations.root
      .where(exam_date: open_date, time_slot_id: ag_exam_type.time_slots.map(&:id))
  }
  let(:registrations_for_pcr_slots) {
    db.registrations.root
      .where(exam_date: open_date, time_slot_id: pcr_exam_type.time_slots.map(&:id))
  }

  let(:base_url)   { 'https://sttestcoviddashboard.blob.core.windows.net/crs' }
  let(:token)      { 'xxx'             }
  let(:ag_cfa_id)  { SecureRandom.uuid }
  let(:pcr_cfa_id) { SecureRandom.uuid }

  subject(:reporter) {
    CovidForm::Reporter.new(
      token: token, ag_cfa_id: ag_cfa_id, pcr_cfa_id: pcr_cfa_id, logging: false,
    )
  }

  it 'works' do
    stub_request(:any, /sttestcoviddashboard.blob.core.windows.net/)

    Timecop.freeze do
      reporter.report(number_of_days: number_of_days)

      url = "#{base_url}/CRS_#{pcr_cfa_id}_#{Time.now.strftime('%Y%m%d%H%M%S')}.json?#{token}"

      expect(
        a_request(:put, url)
        .with(query: token) { |request|
          expect(JSON.parse(request.body))
            .to be_an(Array)
            .and(contain_exactly(
              {
                'cfaId'  => ag_cfa_id,
                'values' => array_including(
                  {
                    'date'             => Date.today.iso8601,
                    'maximum_capacity' => ag_max_capacity,
                    'available_slots'  => ag_max_capacity,
                  },
                  {
                    'date'             => open_date.iso8601,
                    'maximum_capacity' => ag_max_capacity,
                    'available_slots'  => ag_max_capacity - registrations_for_ag_slots.count,
                  },
                  {
                    'date'             => closed_date.iso8601,
                    'maximum_capacity' => 0,
                    'available_slots'  => 0,
                  },
                ),
              }, {
                'cfaId'  => pcr_cfa_id,
                'values' => array_including(
                  {
                    'date'             => Date.today.iso8601,
                    'maximum_capacity' => pcr_max_capacity,
                    'available_slots'  => pcr_max_capacity,
                  },
                  {
                    'date'             => open_date.iso8601,
                    'maximum_capacity' => pcr_max_capacity,
                    'available_slots'  => pcr_max_capacity - registrations_for_pcr_slots.count,
                  },
                  {
                    'date'             => closed_date.iso8601,
                    'maximum_capacity' => 0,
                    'available_slots'  => 0,
                  },
                ),
              }
            ))
        },
      ).to have_been_made
    end
  end
end
# rubocop:enable Metrics/BlockLength, RSpec/ExampleLength, RSpec/MultipleMemoizedHelpers
