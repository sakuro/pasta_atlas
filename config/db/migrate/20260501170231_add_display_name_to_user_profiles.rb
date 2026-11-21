# frozen_string_literal: true

ROM::SQL.migration do
  # Add your migration here.
  #
  # See https://hanakai.org/learn/hanami/v2.3/database/migrations/ for details.
  change do
    alter_table :user_profiles do
      add_column :display_name, String, null: true
    end
  end
end
