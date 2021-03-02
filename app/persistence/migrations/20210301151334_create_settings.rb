# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table(:settings) do
      column :key,   String, null: false, primary_key: true
      column :value, :jsonb, null: false
    end
  end
end
