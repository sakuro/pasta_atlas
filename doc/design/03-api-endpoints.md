# API Endpoints

All endpoints return JSON. Base path: `/api/v1`

Images and mapshot.json are served directly via CloudFront, not through the API.

Page navigation (map list, map viewer) is handled by the `web` slice as server-rendered HTML. The API serves only the client-side islands (map viewer, upload).

Presigned PUT URLs are generated locally by the AWS SDK (no S3 API call). The presigned_urls endpoint does make one S3 ListObjectsV2 call to filter already-uploaded files.

---

## Maps

### GET /api/v1/maps/:ulid

Map details with all complete generations.

**Response `200 OK`:**

```json
{
  "ulid": "01HXYZ...",
  "display_name": "my-save",
  "owner": { "name": "sakuro" },
  "generations": [
    {
      "ulid": "01HABC...",
      "tick": 29386437,
      "metadata_url": "https://cdn.example.com/ae8ec3ab/550f41a9/mapshot.json"
    }
  ]
}
```

`generations` is sorted by `tick` descending. `metadata_url` is the CloudFront URL for the generation's mapshot.json.

**Error responses:**

| Status | Condition |
|---|---|
| `404 Not Found` | Map with given ULID does not exist |

---

## Uploads

### POST /api/v1/uploads

Start an upload session. Creates Map (if new for this user), Generation, and Upload records.

**Request body:**

```json
{
  "metadata": { "...mapshot.json content..." },
  "total_image_count": 42
}
```

**Response `201 Created`:**

```json
{
  "ulid": "01HUPLOAD...",
  "map_ulid": "01HXYZ...",
  "generation_ulid": "01HABC..."
}
```

**Error responses:**

| Status | Condition |
|---|---|
| `409 Conflict` | A `complete` upload already exists for this generation |
| `502 Bad Gateway` | S3 write of `mapshot.json` failed; DB records rolled back |

---

### POST /api/v1/uploads/:ulid/presigned_urls

Request presigned S3 PUT URLs for image files. The server checks existing S3 keys (via ListObjectsV2, 1 API call) and returns URLs only for files not yet uploaded. Send the full filename list each time — the server handles filtering.

**Request body:**

```json
{
  "filenames": ["s1zoom_4/tile_0_0.jpg", "s1zoom_4/tile_1_0.jpg", "..."]
}
```

**Response `200 OK`:**

```json
{
  "presigned_urls": {
    "s1zoom_4_0_0.png": "https://s3.amazonaws.com/bucket/...?X-Amz-Signature=...",
    "s1zoom_4_1_0.png": "https://s3.amazonaws.com/bucket/...?X-Amz-Signature=..."
  }
}
```

May be called multiple times with a subset of filenames (e.g. remaining files after partial upload, or after URL expiry).

**Error responses:**

| Status | Condition |
|---|---|
| `404 Not Found` | Upload with given ULID does not exist |
| `422 Unprocessable Entity` | Upload status is `complete` or `failed` |

---

### PATCH /api/v1/uploads/:ulid

Mark an upload as complete or failed.

**Request body:**

```json
{
  "status": "complete"
}
```

**Response `200 OK`:**

```json
{
  "ulid": "01HUPLOAD...",
  "status": "complete",
  "completed_at": "2026-04-26T01:23:45Z"
}
```

**Error responses:**

| Status | Condition |
|---|---|
| `404 Not Found` | Upload with given ULID does not exist |
