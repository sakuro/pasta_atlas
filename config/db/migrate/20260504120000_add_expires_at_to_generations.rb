# frozen_string_literal: true

ROM::SQL.migration do
  change do
    alter_table :generations do
      add_column :expires_at, :timestamptz, null: true
      add_index :expires_at
    end
  end
end
