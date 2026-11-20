# Upload Flow

## S3 Key Structure

All files for a generation are stored under a per-user prefix:

```
{user_name}/maps/{mapshot_map_id}/{mapshot_unique_id}/mapshot.json
{user_name}/maps/{mapshot_map_id}/{mapshot_unique_id}/{surface_file_prefix}{zoom}/tile_{x}_{y}.jpg
```

Example (user `sakuro`):
```
sakuro/maps/ae8ec3ab/550f41a9/mapshot.json
sakuro/maps/ae8ec3ab/550f41a9/s1zoom_4/tile_0_0.jpg
sakuro/maps/ae8ec3ab/550f41a9/s1zoom_3/tile_0_0.jpg
```

The `metadata_s3_key` stored in DB points to `mapshot.json` within this prefix.

Avatar images use a separate prefix: `avatars/{user_id}/{ulid}.{ext}`

---

## Client-Side Flow

```
[instructions]
  User clicks upload button → modal shows upload instructions
  → User clicks "Select folder" → hidden <input webkitdirectory> triggered
  → User selects a directory; browser delivers all files as a FileList
  → If user cancels: stay in instructions state (modal remains open)
  → If mapshot.json not found in FileList: show error state
  → If more than 10,000 images: show error state
  → If mapshot.json found: parse and proceed to confirming

[confirming]
  → Parse mapshot.json (validate structure)
  → Separate: mapshot.json | image files
  → Show summary to user:
      - Map name (editable; default resolution: existing map name → name → savename → generated name)
      - Surface count
      - Image file count
      - Total file size (sum of all image files)
  → User confirms

[uploading]
  Step 1: POST /api/v1/uploads
    Body: { metadata: <mapshot.json content>, total_image_count: N, name: <display name or null> }
    → Receive: { ulid, map_ulid, generation_ulid }

  Step 2: For each batch of up to 200 image files (sequential):
    2a. POST /api/v1/uploads/:ulid/presigned_posts
        Body: { filenames: ["s1zoom_4/tile_0_0.jpg", ...] }
        → Receive: { presigned_posts: { filename: { url, fields }, ... } }
    2b. Upload each file with a multipart POST to its presigned URL (parallel, concurrency limit 5)
        → On failure: enter error state
    2c. POST /api/v1/uploads/:ulid/verify_batch
        Body: { filenames: [...] }
        → Receive: { verified_bytes }

  Step 3: PATCH /api/v1/uploads/:ulid
    Body: { status: "complete" }

[done]
  → Show link to /maps/:map_ulid?generation=:generation_ulid
```

### Notes

- `mapshot.json` is sent in Step 1 body; the server writes it to S3 directly. The client does not request a presigned POST for it.
- File paths are relative paths within the selected directory (e.g. `s1zoom_4/tile_0_0.jpg`).
- Presigned POSTs are used instead of presigned PUTs because a POST policy can bound the object: `Content-Type` must be `image/jpeg` and the size must be 1 byte to 640 KB (`content-length-range`). A presigned PUT URL cannot enforce a size limit.
- S3 writes are atomic: each file either fully succeeds or fully fails. Re-uploading an existing key overwrites it.
- The browser uploads directly to the S3 bucket, so its CORS policy must allow `POST` (see below).

---

## Server-Side Processing

### POST /api/v1/uploads

1. Require authentication; return `403 Forbidden` for the guest user
2. Parse `metadata` (mapshot.json content) and extract `map_id`, `unique_id` and `tick`
3. Validate the optional display `name` (length and allowed characters); return `422` on failure
4. Find or create `Map` by `(user_id, mapshot_map_id)` using `INSERT ... ON CONFLICT DO NOTHING`
   - A plain transaction is insufficient under `READ COMMITTED`: two concurrent requests can both find "not found" before either inserts
5. Check if `Generation` with `(map_id, mapshot_unique_id)` already exists
   - If exists with a `complete` upload → return `409 Conflict`
   - If exists with a `pending`/`failed` upload → return the existing upload (allow retry)
   - If not exists → create `Generation`
6. Write mapshot.json to S3 at `{user_name}/maps/{mapshot_map_id}/{mapshot_unique_id}/mapshot.json` and set `metadata_s3_key` on the Generation
7. Create `Upload` record (`status: pending`, `total_image_count` from request)
8. Return `{ ulid, map_ulid, generation_ulid }`

Steps 5–7 run inside a single transaction. Step 4 runs before it; if the transaction rolls back (e.g. S3 failure), the Map record is retained — Map creation is idempotent.

### POST /api/v1/uploads/:ulid/presigned_posts

1. Validate `filenames`: at most 200 entries, each matching `s<surface>zoom_<zoom>/tile_<x>_<y>.jpg`; return `400` otherwise
2. Find `Upload` by ULID; return `404` if not found
3. Validate `status` is `pending`; return `422` if `complete` or `failed`
4. Return `403` unless the Map belongs to the current user
5. Record each S3 key in `upload_verification_keys` (the set of keys expected for this upload)
6. Generate a presigned POST per filename (expiry: `PRESIGNED_URL_EXPIRY`, default 1 hour) with conditions `Content-Type: image/jpeg` and `content-length-range` 1..640 KB
7. Return `{ presigned_posts: { filename: { url, fields }, ... } }`

### POST /api/v1/uploads/:ulid/verify_batch

1. Validate `filenames` (non-empty, at most 200); require authentication and ownership of the Map
2. Issue a `HeadObject` for each key (concurrency 20)
3. If any object is missing: enqueue the generation's S3 prefix on the cleanup queue, delete the Generation, and return `422` with `{ error: "verification_failed" }`
4. Otherwise mark the keys verified, add the batch size to `uploads.verified_bytes`, and return `{ verified_bytes }`

Verification makes the size recorded in the database reflect what is actually in S3, independent of the client.

### PATCH /api/v1/uploads/:ulid

1. Find `Upload` by ULID; return `404` if not found; require ownership of the Map
2. For `complete`: the number of verified keys must equal `total_image_count`
3. Append an `upload_events` row (`complete` or `failed`)
4. For `complete`: store `verified_bytes` as the generation's `storage_bytes` and mark the verification as passed
5. Return `{ ulid, status, completed_at }`

---

## Operation Sequence

```mermaid
sequenceDiagram
    actor Client
    participant Action
    participant UC as "Uploads::Create"
    participant IPP as "Uploads::IssuePresignedPosts"
    participant VB as "Uploads::VerifyBatch"
    participant UUS as "Uploads::UpdateStatus"
    participant DB
    participant S3

    Note over Client,S3: Step 1 — POST /api/v1/uploads

    Client->>Action: POST /api/v1/uploads
    Action->>UC: call(user_id, metadata, total_image_count, name)
    UC->>DB: find or create map (ON CONFLICT DO NOTHING)

    alt complete upload exists
        UC-->>Client: 409 Conflict
    else pending/failed upload exists
        UC-->>Client: existing upload
    else no generation
        UC->>DB: INSERT generation
        UC->>S3: PUT mapshot.json
        alt S3 error
            Note over UC,DB: rollback
            UC-->>Client: 502
        else S3 success
            UC->>DB: INSERT upload (status: pending)
            UC-->>Client: 201 Created
        end
    end

    loop each batch of up to 200 files
        Note over Client,S3: Step 2a — POST /presigned_posts
        Client->>Action: POST /presigned_posts {filenames}
        Action->>IPP: call(upload_ulid, filenames, user_id)
        IPP->>DB: record expected keys
        IPP-->>Client: { filename: { url, fields } }

        Note over Client,S3: Step 2b — direct S3 POST
        Client->>S3: POST multipart (policy: image/jpeg, 1..640KB)
        S3-->>Client: 204 No Content

        Note over Client,S3: Step 2c — POST /verify_batch
        Client->>Action: POST /verify_batch {filenames}
        Action->>VB: call(upload, filenames)
        VB->>S3: HeadObject per key
        alt any key missing
            VB->>S3: (cleanup queue) delete prefix
            VB->>DB: DELETE generation
            VB-->>Client: 422 verification_failed
        else all present
            VB->>DB: mark verified, add verified_bytes
            VB-->>Client: { verified_bytes }
        end
    end

    Note over Client,S3: Step 3 — PATCH /api/v1/uploads/:ulid

    Client->>Action: PATCH /uploads/:ulid {status: "complete"}
    Action->>UUS: call(upload_ulid, status, user_id)
    UUS->>DB: count verified keys == total_image_count
    UUS->>DB: INSERT upload_event, set storage_bytes
    UUS-->>Client: 200 OK
```

---

## S3 Configuration Requirements

- Bucket CORS policy must allow `POST` from the application's frontend origin (direct browser upload via presigned POST)
- CloudFront distribution serves the same bucket (read-only, public)
- The cleanup queue (`SQS_S3_CLEANUP_QUEUE_URL`) must exist; `verify_batch` enqueues the generation prefix when verification fails

---

## Error Cases

| Scenario | Handling |
|---|---|
| Directory has no `mapshot.json` | Client-side validation; show error before upload starts |
| Generation already fully uploaded | Server returns `409 Conflict` |
| File is not `image/jpeg` or exceeds 640 KB | S3 rejects the POST against the policy; upload enters error state |
| Presigned POST expires mid-upload | S3 rejects the POST; upload enters error state |
| Object missing after upload | `verify_batch` returns `422`; the generation is deleted and its S3 prefix is scheduled for cleanup |
| Client closes browser during upload | Upload stays `pending`; resumable on next attempt (see below) |
| S3 write fails for `mapshot.json` | Server returns `502`; Generation and Upload records are rolled back |

### Resume design

Resume relies on S3 overwrite semantics:

- On error, the Upload remains `pending`. On retry (same or different session), `POST /api/v1/uploads` returns the existing Upload; the client sends all filenames again through Steps 2a–2c and already-uploaded files are overwritten harmlessly.
- `failed` status is set only when the user explicitly abandons the upload (future: admin tooling). It is not required for the retry flow.
