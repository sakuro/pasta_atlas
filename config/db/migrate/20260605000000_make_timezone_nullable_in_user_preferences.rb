# frozen_string_literal: true

ROM::SQL.migration do
  up do
    alter_table :user_preferences do
      set_column_allow_null :timezone
      set_column_default :timezone, nil
    end
  end

  down do
    run "UPDATE user_preferences SET timezone = 'UTC' WHERE timezone IS NULL"
    alter_table :user_preferences do
      set_column_not_null :timezone
      set_column_default :timezone, "UTC"
    end
  end
end
