# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :maps do
      primary_key :id, type: :Bignum
      String :ulid, size: 26, null: false
      foreign_key :user_id, :users, type: :Bignum, null: false, on_delete: :cascade
      String :mapshot_map_id, null: false
      String :savename, null: false, default: ""
      String :name
      column :created_at, :timestamptz, null: false, default: Sequel.lit("now()")

      index :ulid, unique: true
      index [:user_id, :mapshot_map_id], unique: true
      index :user_id
    end
  end
end
