# frozen_string_literal: true

ROM::SQL.migration do
  up do
    alter_table :uploads do
      set_column_not_null :total_image_count
    end
  end

  down do
    alter_table :uploads do
      set_column_allow_null :total_image_count
    end
  end
end
