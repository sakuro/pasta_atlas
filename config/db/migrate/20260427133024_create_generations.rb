# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :generations do
      primary_key :id, type: :Bignum
      String :ulid, size: 26, null: false
      foreign_key :map_id, :maps, type: :Bignum, null: false, on_delete: :cascade
      String :mapshot_unique_id, null: false
      column :tick, :bigint, null: false
      String :metadata_s3_key, null: false
      column :created_at, :timestamptz, null: false, default: Sequel.lit("now()")

      index :ulid, unique: true
      index [:map_id, :mapshot_unique_id], unique: true
      index :map_id
    end
  end
end
