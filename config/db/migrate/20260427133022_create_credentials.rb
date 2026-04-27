# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :credentials do
      primary_key :id, type: :Bignum
      foreign_key :user_id, :users, type: :Bignum, null: false, on_delete: :cascade
      String :provider, null: false
      String :uid, null: false
      column :data, :jsonb, null: false, default: Sequel.lit("'{}'")
      column :created_at, :timestamptz, null: false, default: Sequel.lit("now()")

      index %i[provider uid], unique: true
      index :user_id
    end
  end
end
