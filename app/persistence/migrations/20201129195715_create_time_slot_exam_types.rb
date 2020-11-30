# frozen_string_literal: true

ROM::SQL.migration do
  up do
    # rubocop:disable Layout/LineLength
    create_table(:time_slot_exam_types) do
      foreign_key :time_slot_id, :time_slots, null: false, on_delete: :cascade, on_update: :cascade
      foreign_key :exam_type,    :exam_types, null: false, on_delete: :cascade, on_update: :cascade, type: String
    end
    # rubocop:enable Layout/LineLength

    # populate join table with cartesian product of time_slots and exam_types
    self[:time_slot_exam_types].multi_insert(
      self[:time_slots].select_map(:id).product(self[:exam_types].select_map(:id))
      .map { |time_slot_id, exam_type| { time_slot_id: time_slot_id, exam_type: exam_type } },
    )
  end

  down do
    drop_table(:time_slot_exam_types)
  end
end
