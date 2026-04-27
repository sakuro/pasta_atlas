# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :uploads do
      primary_key :id, type: :Bignum
      String :ulid, size: 26, null: false
      foreign_key :generation_id, :generations, type: :Bignum, null: false, on_delete: :cascade
      String :status, null: false, default: "pending"
      Integer :total_image_count
      column :created_at, :timestamptz, null: false, default: Sequel.lit("now()")
      column :completed_at, :timestamptz

      index :ulid, unique: true
      index :generation_id, unique: true

      constraint(:status_values) { Sequel.lit("status IN ('pending', 'complete', 'failed')") }
    end
  end
end
