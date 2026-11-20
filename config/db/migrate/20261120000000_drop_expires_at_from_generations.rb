# frozen_string_literal: true

ROM::SQL.migration do
  up do
    # Guest uploads were removed in #43, and the scheduled cleanup stopped running when
    # the service moved to Lambda. Delete what the cleanup would have removed so the
    # rows stop being hidden by the expiry filter this migration makes unnecessary.
    run "DELETE FROM generations WHERE expires_at IS NOT NULL"
    run <<~SQL
      DELETE FROM maps
      WHERE user_id = (SELECT id FROM users WHERE name = 'guest')
        AND id NOT IN (SELECT map_id FROM generations)
    SQL

    alter_table :generations do
      drop_index :expires_at
      drop_column :expires_at
    end
  end

  down do
    alter_table :generations do
      add_column :expires_at, :timestamptz, null: true
      add_index :expires_at
    end
  end
end
