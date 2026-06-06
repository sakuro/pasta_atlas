# frozen_string_literal: true

ROM::SQL.migration do
  up do
    alter_table :generations do
      add_column :storage_bytes, :Bignum
    end
  end

  down do
    alter_table :generations do
      drop_column :storage_bytes
    end
  end
end
