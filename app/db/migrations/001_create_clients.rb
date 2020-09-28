Sequel.migration do
  up do
    create_table(:clients) do
      primary_key :id

      column :first_name,        String,    null: false
      column :last_name,         String,    null: false
      column :municipality,      String,    null: false
      column :zip_code,          Integer,   null: false
      column :email,             String,    null: false, unique: true
      column :phone_number,      String,    null: false, unique: true
      column :insurance_number,  String,    null: false, unique: true
      column :insurance_company, :smallint, null: false
    end
  end

  down do
    drop_table(:clients)
  end
end
