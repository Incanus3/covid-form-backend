# frozen_string_literal: true

ROM::SQL.migration do
  up do
    create_table(:exam_types) do
      column :id,          String, primary_key: true
      column :description, String, null: false, unique: true
    end

    # rubocop:disable Layout/LineLength
    self[:exam_types].multi_insert([
      { id: 'pcr',   description: 'PCR vyšetření (výtěr z nosu a následné laboratorní zpracování)' },
      { id: 'rapid', description: 'RAPID test (orientační test z kapky krve)'                      },
      { id: 'ag',    description: 'Antigen test (výtěr z nosu a okamžitý orientační test)'         },
    ])
    # rubocop:enable Layout/LineLength

    alter_table(:registrations) do
      add_foreign_key [:exam_type], :exam_types
    end
  end

  down do
    alter_table(:registrations) do
      drop_foreign_key [:exam_type]
    end

    drop_table(:exam_types)
  end
end
