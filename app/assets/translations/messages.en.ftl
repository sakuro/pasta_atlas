-app-name = Pasta Atlas
-discord = Discord
-github = GitHub

## App
app-name = { -app-name }

## Surfaces
surface-nauvis = Nauvis
surface-vulcanus = Vulcanus
surface-gleba = Gleba
surface-fulgora = Fulgora
surface-aquilo = Aquilo

## Nav
nav-log-out = Log out
nav-log-in = Log in
nav-log-in-discord = Log in with { -discord }
nav-log-in-github = Log in with { -github }
nav-source-code = Source code

## Registration
registration-title = Create your account
registration-username = Username
    .help = 1–39 characters. Letters, numbers, hyphens, and underscores. Must start and end with a letter or number.
registration-submit = Create account

## Registration errors
error-username-empty = Username must not be empty.
error-username-too-long = Username must be 39 characters or fewer.
error-username-invalid-chars = Username may only contain letters, numbers, hyphens, and underscores, and must start and end with a letter or number.
error-username-reserved = That username is reserved.
error-username-taken = That username is already taken.

## User page
user-tab-profile = Profile
user-tab-preferences = Preferences
user-tab-profile-edit =
    .title = Edit profile
user-tab-preferences-edit =
    .title = Edit preferences
user-recent-maps = Recent Maps
user-connected-accounts-label = Connected Accounts
provider-discord = { -discord }
provider-github = { -github }
user-timezone-label = Timezone
user-locale-label = Locale

## Edit page
edit-title = Edit
edit-avatar-label = Avatar
edit-display-name = Display name
    .help = Up to 64 characters. Leave blank to use your username.
edit-save-profile = Save Profile
edit-timezone-label = Timezone
edit-locale = Locale
    .not-set = (not set)
edit-save-preferences = Save Preferences
edit-cancel = Cancel

## Connected accounts
credential-connect-discord = Connect with { -discord }
credential-connect-github = Connect with { -github }
credential-disconnect-discord = Disconnect { -discord }
credential-disconnect-github = Disconnect { -github }
credential-last-hint = At least one connected account is required.

## Credential errors
error-credential-conflict = That account is already linked to another user.
error-credential-last = At least one connected account is required.

## Map card
map-card-updated-at = { $date }

## Pagination
pagination-previous = Previous
pagination-next = Next


## Upload modal
upload-button = Upload
upload-modal-title = Upload Mapshot
upload-instructions-folder = Select the folder containing mapshot.json.
upload-instructions-folder-path = Typical mapshot folder:
upload-instructions-generations = You can upload different generations of an existing map.
upload-instructions-guest = Uploads from guest accounts are deleted after approximately one week.
upload-select-folder = Select Folder
upload-cancel = Cancel
upload-map-title = Map title
upload-surfaces = Surfaces
upload-images = Images
upload-total-size = Total size
upload-start = Start Upload
upload-back = Back
upload-progress = Uploading { $progress } / { $total } files...
upload-complete = Upload complete!
upload-view-map = View Map
upload-close = Close
upload-dismiss = Dismiss
upload-error-not-found = mapshot.json was not found in the selected folder.
upload-error-parse = Failed to parse mapshot.json.
upload-error-conflict = This generation has already been uploaded.
upload-error-http = Upload failed (HTTP { $status }).
upload-error-network = Network error. Please check your connection and try again.
upload-error-urls-http = Failed to get upload URLs (HTTP { $status }).
upload-error-urls-network = Network error getting upload URLs.
upload-error-file = Failed to upload: { $details }
upload-error-finalize = Images uploaded, but finalization failed.
upload-error-finalize-network = Images uploaded, but network error during finalization.

## Avatar upload
avatar-change = Change
avatar-remove = Remove
avatar-cancel = Cancel
avatar-dismiss = Dismiss
avatar-error-too-large-file-size = File must be 5 MiB or smaller.
avatar-error-too-small-pixel-size = Image must be { $min }×{ $min } or larger.
avatar-error-too-large-pixel-size = Image must be { $max }×{ $max } or smaller.
avatar-error-read = Failed to read image.
avatar-error-remove-http = Failed to remove avatar (HTTP { $status }).
avatar-error-network = Network error. Please try again.
avatar-error-url-http = Failed to get upload URL (HTTP { $status }).
avatar-error-upload-http = Upload failed (HTTP { $status }).
avatar-error-upload-network = Network error during upload.

## Map viewer
map-layer-train-stations = Train stations
map-layer-tags = Tags
map-info-button =
    .title = Map info

## Map info modal
map-info-title = Map Info
map-info-seed = Map seed
map-info-exchange = Map exchange
map-info-exchange-show =
    .title = Show
map-info-copy =
    .title = Copy
map-info-exchange-hide =
    .title = Hide
map-info-tick = Tick
map-info-ticks-played = Ticks played
map-info-game-version = Game version
map-info-mods = MODs
map-info-mods-count =
    { $count ->
        [one] { $count } MOD
       *[other] { $count } MODs
    }
map-info-close = Close

## Share buttons
share-x =
    .title = Share on X
share-bluesky =
    .title = Share on Bluesky
share-reddit =
    .title = Share on Reddit
share-copy-link =
    .title = Copy link
