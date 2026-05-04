# frozen_string_literal: true

ROM::SQL.migration do
  up do
    alter_table :user_profiles do
      drop_column :timezone
    end
  end

  down do
    alter_table :user_profiles do
      add_column :timezone, String, null: false, default: "UTC"
    end

    run <<~SQL
      UPDATE user_profiles up
      SET timezone = COALESCE(pref.timezone, 'UTC')
      FROM user_preferences pref
      WHERE pref.user_id = up.user_id
    SQL
  end
end
