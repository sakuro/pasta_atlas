# frozen_string_literal: true

ROM::SQL.migration do
  up do
    alter_table :uploads do
      add_column :verification_status, :text, null: false, default: "pending"
      add_column :verified_bytes, :Bignum, null: false, default: 0
      add_column :verified_at, :timestamptz
      add_constraint(
        :verification_status_values,
        Sequel.lit("verification_status IN ('pending', 'passed', 'failed')")
      )
    end

    create_table :upload_verification_keys do
      primary_key :id, type: :Bignum
      foreign_key :upload_id, :uploads, type: :Bignum, null: false, on_delete: :cascade
      String :s3_key, null: false
      column :verified_at, :timestamptz
      column :size_bytes, :Bignum

      index %i[upload_id s3_key], unique: true
    end
  end

  down do
    drop_table :upload_verification_keys

    alter_table :uploads do
      drop_constraint :verification_status_values
      drop_column :verified_at
      drop_column :verified_bytes
      drop_column :verification_status
    end
  end
end
