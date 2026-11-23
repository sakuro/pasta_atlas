# frozen_string_literal: true

ROM::SQL.migration do
  up do
    # The tile sizes are now summed from upload_verification_keys when the upload completes,
    # so the column keeps only the size of mapshot.json. The size of mapshot.json cannot be
    # recovered from the old running total, so an upload still pending at migration time
    # keeps its tile bytes here and completes with a storage_bytes that counts them twice.
    alter_table :uploads do
      rename_column :verified_bytes, :metadata_bytes
    end
    # PostgreSQL 18 names NOT NULL constraints after the column and keeps the name on a rename.
    run "ALTER TABLE uploads RENAME CONSTRAINT uploads_verified_bytes_not_null TO uploads_metadata_bytes_not_null"
  end

  down do
    run "ALTER TABLE uploads RENAME CONSTRAINT uploads_metadata_bytes_not_null TO uploads_verified_bytes_not_null"
    alter_table :uploads do
      rename_column :metadata_bytes, :verified_bytes
    end
  end
end
