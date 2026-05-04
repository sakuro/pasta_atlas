# frozen_string_literal: true

ROM::SQL.migration do
  up do
    create_table :user_preferences do
      primary_key :id, type: :Bignum
      foreign_key :user_id, :users, type: :Bignum, null: false, on_delete: :cascade
      column :timezone, String, null: false, default: "UTC"
      column :locale, String, null: true
      index :user_id, unique: true
    end

    run <<~SQL
      INSERT INTO user_preferences (user_id, timezone)
      SELECT user_id, timezone FROM user_profiles
      ON CONFLICT (user_id) DO NOTHING
    SQL
  end

  down do
    drop_table :user_preferences
  end
end
