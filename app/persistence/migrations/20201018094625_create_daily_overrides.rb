# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table(:daily_overrides) do
      primary_key :id

      column :date,               Date, null: false, unique: true
      column :registration_limit, Integer
    end
  end
end
