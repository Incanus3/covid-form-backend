require 'spec_helper'
require 'webmock/rspec'
require 'spec/feature/registration/helpers'
require 'scripts/send_capacity_report'

RSpec.feature 'send_capacity_report script' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:config, :db]

  subject(:reporter) { CovidForm::Reporter.new }

  let(:open_date)                { Date.today + 1 }
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

  it 'works' do
    stub_request(:any, /sttestcoviddashboard.blob.core.windows.net/)

    reporter.report(number_of_days: 7)

    # this doesn't work, because WebMock::RequestPattern::BodyPattern#matches? decodes body only if
    # the matcher is either a hash or WebMock::Matchers::HashIncludingMatcher (returned by
    # has_including method from WebMock::API, this is not the same as rspec built-in
    # a_hash_including) not only does this fail, but because
    # RSpec::Matchers::BuiltIn::Include#actual_collection_includes?  calls .include?(<matcher
    # returned by a_hash_including>) on the body string, it fails with TypeError: no implicit
    # conversion of RSpec::Matchers::AliasedMatcher into String, which is pretty hard to find, since
    # the default backtrace_exclusion_patterns filter the rspec lines in the backtrace out
    # TODO: report an issue to rspec - string.include? should never be called with a matcher
    # TODO: possibly make a feature request to webmock to support this case for a JSON array body
    # expect(a_request(:post, 'https://sttestcoviddashboard.blob.core.windows.net/crs/')
    #   .with(body: match(a_collection_including(a_hash_including())))).to have_been_made

    total_coef_sum  = db.time_slots.all.sum(&:limit_coefficient)
    ag_exam_type    = db.exam_types.root.where(id: 'ag').combine(:time_slots).one!
    ag_coef_sum     = ag_exam_type.time_slots.sum(&:limit_coefficient)
    ag_max_capacity = daily_registration_limit * ag_coef_sum / total_coef_sum

    registrations_for_ag_slots = db.registrations.root
      .where(exam_date: open_date, time_slot_id: ag_exam_type.time_slots.map(&:id))

    expect(
      a_request(:put, 'https://sttestcoviddashboard.blob.core.windows.net/crs/')
      .with { |request|
        expect(JSON.parse(request.body)).to include(
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
        )
      },
    ).to have_been_made
  end
end
