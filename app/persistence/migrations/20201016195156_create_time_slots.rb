# frozen_string_literal: true

require 'lib/utils'

ROM::SQL.migration do
  up do
    create_table(:time_slots) do
      primary_key :id

      column :name,       String, unique:    true, null: false
      column :start_time, Time,   only_time: true, null: false
      column :end_time,   Time,   only_time: true, null: false
    end

    alter_table(:registrations) do
      add_foreign_key :time_slot_id, :time_slots, null: false
    end

    # rubocop:disable Layout/LineLength
    self[:time_slots].multi_insert([
      { name: 'slot 1', start_time: Utils::Time.today_at( 8, 0), end_time: Utils::Time.today_at( 9, 0) },
      { name: 'slot 2', start_time: Utils::Time.today_at( 9, 0), end_time: Utils::Time.today_at(10, 0) },
      { name: 'slot 3', start_time: Utils::Time.today_at(10, 0), end_time: Utils::Time.today_at(11, 0) },
      { name: 'slot 4', start_time: Utils::Time.today_at(11, 0), end_time: Utils::Time.today_at(12, 0) },
    ])
    # rubocop:enable Layout/LineLength
  end

  down do
    alter_table(:registrations) do
      drop_foreign_key :time_slot_id
    end

    drop_table(:time_slots)
  end
end
