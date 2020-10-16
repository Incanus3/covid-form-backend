# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table(:clients) do
      primary_key :id

      column :first_name,        String,    null: false
      column :last_name,         String,    null: false
      column :municipality,      String,    null: false
      column :zip_code,          String,    null: false
      column :email,             String,    null: false
      column :phone_number,      String,    null: false
      column :insurance_number,  String,    null: false, unique: true
      column :insurance_company, :smallint, null: false
    end
  end
end
