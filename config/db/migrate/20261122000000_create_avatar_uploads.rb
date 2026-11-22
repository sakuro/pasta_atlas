# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :avatar_uploads do
      primary_key :id, type: :Bignum
      foreign_key :user_id, :users, type: :Bignum, null: false, on_delete: :cascade
      String :s3_key, null: false
      String :content_type, null: false
      column :expires_at, :timestamptz, null: false
      column :consumed_at, :timestamptz
      column :created_at, :timestamptz, null: false, default: Sequel.lit("now()")

      index :s3_key, unique: true
      index %i[user_id consumed_at]
    end
  end
end
