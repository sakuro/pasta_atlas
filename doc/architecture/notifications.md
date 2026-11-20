# Notifications

## Overview

Users receive two kinds of notifications:

| Kind | Example | Recipient |
|---|---|---|
| Announcement | System news, maintenance | All users |
| User notification | Reaction to your map | Specific user |

Announcements are stored once and shared across all users. User notifications are stored per recipient. Read state is tracked separately for both kinds.

Messages are written in English. The UI may offer a translate button backed by an external service; no server-side i18n is required.

## Data Model

### announcements

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| ulid | varchar(26) | NOT NULL |
| actor_id | bigint | NOT NULL, REFERENCES users(id) |
| title | varchar | NOT NULL |
| body | text | NOT NULL |
| created_at | timestamptz | NOT NULL |

Indexes:
- UNIQUE on `ulid`

`actor_id` always refers to the Compilatron account (see [Compilatron Account](#compilatron-account)).

### announcement_reads

Presence of a row means the user has read the announcement.

| Column | Type | Constraints |
|---|---|---|
| receiver_id | bigint | NOT NULL, REFERENCES users(id) |
| announcement_id | bigint | NOT NULL, REFERENCES announcements(id) |
| created_at | timestamptz | NOT NULL |

Primary key: `(receiver_id, announcement_id)`

### notifications

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| ulid | varchar(26) | NOT NULL |
| receiver_id | bigint | NOT NULL, REFERENCES users(id) |
| type | varchar | NOT NULL |
| actor_id | bigint | NOT NULL, REFERENCES users(id) |
| subject_type | varchar | |
| subject_id | bigint | |
| created_at | timestamptz | NOT NULL |

Indexes:
- UNIQUE on `ulid`
- on `(receiver_id, created_at DESC)`
- on `(subject_type, subject_id)`

`type` is enforced with a CHECK constraint (not a PostgreSQL ENUM; see [DB Schema](02-db-schema.md) enum strategy).

Display text is rendered on the frontend from `type` + `actor_id` + `subject_type` + `subject_id` at read time.

### notification_reads

Presence of a row means the user has read the notification.

| Column | Type | Constraints |
|---|---|---|
| receiver_id | bigint | NOT NULL, REFERENCES users(id) |
| notification_id | bigint | NOT NULL, REFERENCES notifications(id) |
| created_at | timestamptz | NOT NULL |

Primary key: `(receiver_id, notification_id)`

## UI

### Notification Bell (Navbar)

Displayed only to logged-in users; hidden for guests.

- Unread notifications exist: bell icon (`fa-bell`) with a dot badge
- No unread notifications: bell icon only
- Clicking navigates to `/notifications`

### Notifications Page (`/notifications`)

Requires authentication. Returns 404 for unauthenticated requests (hides the page's existence from guests).

Announcements and user notifications are merged into a single list ordered by `created_at DESC`, with pagination.

#### List Item (collapsed)

| Element | Notes |
|---|---|
| Type icon | e.g. `fa-bullhorn` for announcements, `fa-heart` for reactions |
| Title | Bold if unread |
| Timestamp | Formatted in the user's configured timezone |

For announcements, `title` is the `announcements.title` column. For user notifications, title is rendered from `type` + `actor` + `subject`.

#### Click Behavior

Clicking an item always marks it as read (inserts a row into `announcement_reads` or `notification_reads`). Title returns to normal weight once read.

If the item has a body, it also expands to show the full body (accordion, one item open at a time). Items without a body do not expand.

## Compilatron Account

A dedicated User record (`name: "compilatron"`) acts as the actor for all announcements. This account must exist as seed data before any announcement can be created.

## Out of Scope

- Push notifications (email, web push)
- Notification preferences (opt-out per type)
- Notification expiry / deletion
