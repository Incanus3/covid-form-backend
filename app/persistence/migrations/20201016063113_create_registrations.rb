# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table(:registrations) do
      primary_key :id

      column :registered_at,  DateTime, null: false
      column :requestor_type, String,   null: false
      column :exam_type,      String,   null: false
      column :exam_date,      Date,     null: false

      foreign_key :client_id, :clients, null: false, on_delete: :cascade, on_update: :cascade

      unique [:client_id, :exam_date]
    end
  end
end
