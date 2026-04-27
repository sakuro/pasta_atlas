# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :users do
      primary_key :id, type: :Bignum
    end
  end
end
