# frozen_string_literal: true

ROM::SQL.migration do
  up do
    # A map without a name was shown by its savename, then by its mapshot map id.
    # Store that as the name so the shown names stay the same.
    run <<~SQL
      UPDATE maps
      SET name = COALESCE(NULLIF(savename, ''), mapshot_map_id)
      WHERE name IS NULL
    SQL

    alter_table :maps do
      set_column_not_null :name
      drop_column :savename
    end
  end

  down do
    alter_table :maps do
      add_column :savename, String, null: false, default: ""
      set_column_allow_null :name
    end
  end
end
