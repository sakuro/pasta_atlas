# frozen_string_literal: true

ROM::SQL.migration do
  up do
    alter_table :user_preferences do
      add_column :relative_timestamps, TrueClass, null: false, default: false
    end
  end

  down do
    alter_table :user_preferences do
      drop_column :relative_timestamps
    end
  end
end
