# frozen_string_literal: true

ROM::SQL.migration do
  change do
    alter_table :user_profiles do
      add_column :timezone, String, null: false, default: "UTC"
    end
  end
end
