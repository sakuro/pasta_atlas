# frozen_string_literal: true

ROM::SQL.migration do
  up do
    create_table :upload_events do
      primary_key :id, type: :Bignum
      foreign_key :upload_id, :uploads, type: :Bignum, null: false, on_delete: :cascade
      String :event_type, null: false
      column :occurred_at, :timestamptz, null: false, default: Sequel.lit("now()")

      index :upload_id
      constraint(:event_type_values) { Sequel.lit("event_type IN ('pending', 'complete', 'failed')") }
    end

    # Migrate existing data: one pending event at created_at for every upload
    run <<~SQL
      INSERT INTO upload_events (upload_id, event_type, occurred_at)
      SELECT id, 'pending', created_at FROM uploads;
    SQL

    # For uploads already complete or failed, append a second event
    run <<~SQL
      INSERT INTO upload_events (upload_id, event_type, occurred_at)
      SELECT id, status, COALESCE(completed_at, created_at + interval '1 second')
      FROM uploads
      WHERE status IN ('complete', 'failed');
    SQL

    alter_table :uploads do
      drop_constraint :status_values
      drop_column :status
      drop_column :completed_at
    end

    run <<~SQL
      CREATE VIEW current_upload_statuses AS
      SELECT DISTINCT ON (upload_id)
        upload_id,
        event_type AS status,
        occurred_at
      FROM upload_events
      ORDER BY upload_id, occurred_at DESC, id DESC;
    SQL
  end

  down do
    run "DROP VIEW current_upload_statuses;"

    alter_table :uploads do
      add_column :status, String, null: false, default: "pending"
      add_column :completed_at, :timestamptz
      add_constraint(:status_values) { Sequel.lit("status IN ('pending', 'complete', 'failed')") }
    end

    # Restore status and completed_at from the latest event per upload
    run <<~SQL
      UPDATE uploads u
      SET
        status       = e.event_type,
        completed_at = CASE WHEN e.event_type IN ('complete', 'failed') THEN e.occurred_at END
      FROM (
        SELECT DISTINCT ON (upload_id) upload_id, event_type, occurred_at
        FROM upload_events
        ORDER BY upload_id, occurred_at DESC
      ) e
      WHERE u.id = e.upload_id;
    SQL

    drop_table :upload_events
  end
end
