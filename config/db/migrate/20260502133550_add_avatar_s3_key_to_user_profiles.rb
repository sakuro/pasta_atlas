# frozen_string_literal: true

ROM::SQL.migration do
  change do
    alter_table :user_profiles do
      add_column :avatar_s3_key, String, null: true
    end
  end
end
