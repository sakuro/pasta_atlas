-app-name = Pasta Atlas
-mapshot = Mapshot
-discord = Discord
-github = GitHub
-steam = Steam
-factorio = Factorio

## App
app-name = { -app-name }
discord-name = { -discord }
factorio-name = { -factorio }
github-name = { -github }
mapshot-name = { -mapshot }
steam-name = { -steam }

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
nav-log-in-steam = Log in with { -steam }

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
user-tab-maps = Recent Maps
user-tab-profile = Profile
user-tab-preferences = Preferences
user-tab-credentials = Connections
user-tab-danger = Delete Account
user-tab-profile-edit =
    .title = Edit profile
user-tab-preferences-edit =
    .title = Edit preferences
user-recent-maps = Recent Maps
user-connected-accounts-label = Connected Accounts
provider-discord = { -discord }
provider-github = { -github }
provider-steam = { -steam }
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
    .use-browser = (Use browser)
edit-time-display = Time display
    .relative = Show relative timestamps (e.g. "3 days ago")
edit-save-preferences = Save Preferences
edit-cancel = Cancel

## Danger zone
account-delete-title = Delete Account
account-delete-warning = This action cannot be undone. All maps you own will also be deleted.
account-delete-confirm-label = Type your username to confirm:
account-delete-button = Delete My Account

## Connected accounts
credential-connect-discord = Connect with { -discord }
credential-connect-github = Connect with { -github }
credential-connect-steam = Connect with { -steam }
credential-disconnect-discord = Disconnect { -discord }
credential-disconnect-github = Disconnect { -github }
credential-disconnect-steam = Disconnect { -steam }
credential-last-hint = At least one connected account is required.

## Credential errors
error-credential-conflict = That account is already linked to another user.
error-credential-last = At least one connected account is required.

## Map notices
map-deletion-requested = Your map has been queued for deletion. It may remain visible for a short time.

## Map card
map-card-updated-at = { $date }

## Pagination
pagination-previous = Previous
pagination-next = Next


## Upload modal
upload-button = Upload
upload-modal-title = Upload { -mapshot }
upload-instructions-folder = Select the folder containing mapshot.json.
upload-instructions-folder-path = Typical { -mapshot } folder:
upload-copy-path-windows =
    .title = Copy path — paste in folder dialog (Ctrl+L)
upload-copy-path-macos =
    .title = Copy path — paste in Finder dialog (⌘⇧G)
upload-copy-path-linux =
    .title = Copy path — paste in folder dialog (Ctrl+L)
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

## How to upload modal
how-to-upload-button =
    .title = How to upload
how-to-upload-title = How to upload
how-to-upload-close = Close
how-to-upload-step1-heading = 1. Install the { -mapshot } MOD
how-to-upload-step1-body = Install <a data-l10n-name="mapshot-link">{ -mapshot }</a> from { -factorio }'s in-game Mod menu and restart the game.
how-to-upload-step2-heading = 2. Capture your map
how-to-upload-step2-open-console = Open the in-game console and run:
how-to-upload-step2-wait = The game may appear unresponsive while { -mapshot } is working — wait until it returns to normal.
how-to-upload-achievement-warning = To avoid affecting achievements, do not save your game while { -mapshot } is installed. Uninstall { -mapshot } after capturing.
how-to-upload-step3-heading = 3. Upload
how-to-upload-step3-click-upload = Click "Upload" in the navigation bar.
how-to-upload-step3-select-folder = Click "Select Folder" and select the subfolder containing <code data-l10n-name="filename">mapshot.json</code> (not the file itself).
how-to-upload-step3-confirm = Confirm the map title and details, then click "Start Upload".
how-to-upload-step3-view = When the upload completes, click "View Map".
how-to-upload-tip = You can upload the same map at different game ticks — each upload becomes a separate generation you can switch between in the map viewer.

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
map-name-edit-button =
    .title = Edit map name
map-name-save-button =
    .title = Save
map-name-cancel-button =
    .title = Cancel
map-delete-button =
    .title = Delete map
map-delete-confirm-title = Delete map
map-delete-confirm-message = This map and all its data will be permanently deleted. Are you sure?
map-delete-confirm-button = Delete
map-delete-cancel-button = Cancel

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
map-info-tick-help =
    .title = The in-game clock at the time this map was captured. Does not advance while the game is paused.
map-info-ticks-played = Ticks played
map-info-ticks-played-help =
    .title = Total ticks simulated since this game was created, including ticks processed while the game clock was paused.
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
nav-about = About
nav-privacy-policy = Privacy Policy
nav-terms-of-service = Terms of Service

## Registration: terms agreement
registration-terms-agree = I agree to the above.
