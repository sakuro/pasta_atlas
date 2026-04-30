# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :user_profiles do
      primary_key :id, type: :Bignum
      foreign_key :user_id, :users, type: :Bignum, null: false, on_delete: :cascade
      column :created_at, :timestamptz, null: false, default: Sequel.lit("now()")

      index :user_id, unique: true
    end
  end
end
