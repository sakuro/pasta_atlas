# frozen_string_literal: true

ROM::SQL.migration do
  # Add your migration here.
  #
  # See https://guides.hanamirb.org/v2.3/database/migrations/ for details.
  change do
    alter_table :user_profiles do
      add_column :display_name, String, null: true
    end
  end
end
