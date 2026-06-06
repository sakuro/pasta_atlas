-app-name = Pasta Atlas
-mapshot = Mapshot
-discord = Discord
-github = GitHub
-steam = Steam
-factorio = Factorio

### Global

## App
app-name = { -app-name }
discord-name = { -discord }
factorio-name = { -factorio }
github-name = { -github }
mapshot-name = { -mapshot }
steam-name = { -steam }

## Surfaces
surface-nauvis = 諾維斯星
surface-vulcanus = 武卡努斯星
surface-gleba = 葛萊芭星
surface-fulgora = 弗戈拉星
surface-aquilo = 阿魁洛星

## Errors
error-load-failed = 資料載入失敗。
error-user-not-found = 找不到該使用者。
error-map-not-found = 找不到該地圖。
error-user-forbidden = 此頁面無法顯示。
error-page-not-found = 找不到該頁面。

### Navigation
nav-log-out = 登出
nav-log-in = 登入
nav-log-in-discord = 以 { -discord } 登入
nav-log-in-github = 以 { -github } 登入
nav-log-in-steam = 以 { -steam } 登入
nav-about = 關於
nav-privacy-policy = 隱私政策
nav-terms-of-service = 服務條款

### Authentication

## Registration
registration-title = 建立帳號
registration-username = 使用者名稱
registration-username-help = 1–15 個字元，可使用英文字母、數字、連字號和底線，開頭與結尾必須為英文字母或數字。
registration-terms-agree = 我同意以上內容。
registration-submit = 建立帳號

## Registration errors
error-username-empty = 請輸入使用者名稱。
error-username-too-long = 使用者名稱不得超過 15 個字元。
error-username-invalid-chars = 使用者名稱只能包含英文字母、數字、連字號和底線，且開頭與結尾必須為英文字母或數字。
error-username-reserved = 此使用者名稱已被保留。
error-username-taken = 此使用者名稱已被使用。

### User Account

## User page
user-tab-maps = 最近的地圖
user-tab-profile = 個人資料
user-tab-preferences = 偏好設定
user-tab-credentials = 帳號連結
user-tab-danger = 刪除帳戶
user-tab-profile-edit =
    .title = 編輯個人資料
user-tab-preferences-edit =
    .title = 編輯偏好設定
user-connected-accounts-label = 已連結帳號
provider-discord = { -discord }
provider-github = { -github }
provider-steam = { -steam }
user-timezone-label = 時區
user-locale-label = 語言

## Edit page
edit-title = 編輯
edit-avatar-label = 頭像
edit-display-name = 顯示名稱
edit-display-name-help = 最多 30 個字元，留空則顯示使用者名稱。
edit-save-profile = 儲存個人資料
edit-timezone-label = 時區
edit-timezone-use-browser = （依瀏覽器設定）
edit-locale = 語言
edit-locale-use-browser = （依瀏覽器設定）
edit-time-display = 時間顯示
edit-time-display-relative = 顯示相對時間（如「3天前」）
edit-save-preferences = 儲存偏好設定
edit-cancel = 取消

## Danger zone
account-delete-title = 刪除帳戶
account-delete-warning = 此操作無法復原。您所擁有的所有地圖資料也將被刪除。
account-delete-confirm-label = 請輸入使用者名稱以確認：
account-delete-button = 刪除我的帳戶

## Connected accounts
credential-connect-discord = 連結 { -discord }
credential-connect-github = 連結 { -github }
credential-connect-steam = 連結 { -steam }
credential-disconnect-discord = 解除連結 { -discord }
credential-disconnect-github = 解除連結 { -github }
credential-disconnect-steam = 解除連結 { -steam }
credential-last-hint = 至少需要一個已連結帳號。

## Success notices
profile-saved = 個人資料已儲存。
preferences-saved = 設定已儲存。
credential-disconnected = 帳號已解除連結。

## Errors
error-credential-conflict = 此帳號已連結至其他使用者。
error-credential-last = 至少需要一個已連結帳號。
error-profile-display-name-too-long = 顯示名稱不得超過 30 個字元。
error-profile-display-name-invalid-chars = 顯示名稱包含不允許的字元。

### Maps

## Map card
map-card-updated-at = { $date }

## Map notices
map-deletion-requested = 您的地圖已加入刪除佇列。可能會短暫顯示一段時間。

## Pagination
pagination-previous = 上一頁
pagination-next = 下一頁

### Upload

## Upload modal
upload-button = 上傳
upload-button-guest =
    .title = 登入後即可上傳地圖
upload-modal-title = 上傳 { -mapshot }
upload-modal-title-guest = 上傳 { -mapshot }（訪客）
upload-instructions-folder = 請選取包含 <code data-l10n-name="filename">mapshot.json</code> 的<strong>資料夾</strong>。
upload-instructions-folder-path = { -mapshot } 的輸出資料夾（Steam 版）：
upload-copy-path-windows =
    .title = 複製路徑 — 在資料夾對話框中按 Ctrl+L 貼上
upload-copy-path-macos =
    .title = 複製路徑 — 在 Finder 對話框中按 ⌘⇧G 貼上
upload-copy-path-linux =
    .title = 複製路徑 — 在資料夾對話框中按 Ctrl+L 貼上
upload-instructions-folder-subfolder = 接著選取您的地圖與世代的子資料夾。例如：
upload-instructions-generations = 您可以上傳同一張地圖的不同世代。
upload-instructions-guest = 訪客帳號的上傳在上傳後無法更改地圖名稱。無法手動刪除，約兩天後會自動刪除。
upload-select-folder = 選取資料夾
upload-cancel = 取消
upload-map-title = 地圖標題
upload-map-name-locked =
    .title = 以訪客身分上傳後無法更改地圖名稱
upload-surfaces = 表面
upload-images = 圖片數量
upload-total-size = 總大小
upload-start = 開始上傳
upload-reselect-folder = 重新選取資料夾
upload-preparing = 正在準備 { $prepared } / { $total } 個檔案...
upload-progress = 正在上傳第 { $progress } / { $total } 個檔案...
upload-complete = 上傳完成！
upload-view-map = 查看地圖
upload-close = 關閉
upload-dismiss = 關閉
upload-error-not-found = 在選取的資料夾中未找到 mapshot.json。
upload-error-parse = 無法解析 mapshot.json。
upload-error-conflict = 此世代已上傳過。
upload-error-expired = 此地圖已過期，無法再上傳。
upload-error-http = 上傳失敗（HTTP { $status }）。
upload-error-network = 網路錯誤，請確認連線後重試。
upload-error-urls-http = 無法取得上傳網址（HTTP { $status }）。
upload-error-urls-network = 取得上傳網址時發生網路錯誤。
upload-error-file = 上傳失敗：{ $details }
upload-error-finalize = 圖片已上傳，但完成處理失敗。
upload-error-finalize-network = 圖片已上傳，但完成處理時發生網路錯誤。

## How to upload
how-to-upload-button =
    .title = 上傳說明
how-to-upload-title = 上傳說明
how-to-upload-close = 關閉
how-to-upload-step1-heading = 1. 安裝 { -mapshot } MOD
how-to-upload-step1-body = 從 { -factorio } 遊戲內的 MOD 選單安裝 <a data-l10n-name="mapshot-link">{ -mapshot }</a>，然後重新啟動遊戲。
how-to-upload-step2-heading = 2. 擷取地圖
how-to-upload-step2-open-console = 開啟遊戲內主控台並執行：
how-to-upload-step2-wait = 擷取期間遊戲可能暫時無回應，請等待其恢復正常。
how-to-upload-achievement-warning = 為避免影響成就，請勿在安裝 { -mapshot } 的狀態下儲存遊戲，擷取後請解除安裝 { -mapshot }。
how-to-upload-step3-heading = 3. 上傳
how-to-upload-step3-click-upload = 點擊導覽列中的「上傳」。
how-to-upload-step3-select-folder = 點擊「選取資料夾」並選擇包含 <code data-l10n-name="filename">mapshot.json</code> 的子資料夾（請選擇資料夾，而非檔案本身）。
how-to-upload-step3-confirm = 確認地圖標題和詳細資訊後，點擊「開始上傳」。
how-to-upload-step3-view = 上傳完成後，點擊「查看地圖」。
how-to-upload-tip = 您可以在不同遊戲刻上傳同一張地圖，每次上傳會成為獨立的世代，可在地圖檢視器中切換。

### Map Viewer

## Map viewer
map-layer-train-stations = 火車站
map-layer-tags = 標籤
map-layer-group-planets = 星球
map-layer-group-space-platforms = 太空平台
map-layer-group-other = 其他
map-control-box-zoom = 點擊後在地圖上繪製矩形以放大
map-control-zoom-in = 放大
map-control-zoom-out = 縮小
map-info-button =
    .title = 地圖資訊
map-name-edit-button =
    .title = 編輯地圖名稱
map-name-save-button =
    .title = 儲存
map-name-cancel-button =
    .title = 取消
map-delete-button =
    .title = 刪除地圖
map-delete-confirm-title = 刪除地圖
map-delete-confirm-message = 此地圖及其所有資料將永久刪除。確定嗎？
map-delete-confirm-button = 刪除
map-delete-cancel-button = 取消

## Map errors
error-map-name-too-long = 地圖名稱不得超過 30 個字元。
error-map-name-invalid-chars = 地圖名稱包含不允許的字元。

## Map info modal
map-info-title = 地圖資訊
map-info-seed = 地圖種子
map-info-exchange = 地圖交換字串
map-info-exchange-show =
    .title = 顯示
map-info-copy =
    .title = 複製
map-info-exchange-hide =
    .title = 隱藏
map-info-tick = 刻
map-info-tick-help =
    .title = 此地圖擷取時的遊戲內時刻。遊戲暫停期間不會推進。
map-info-ticks-played = 已遊玩刻數
map-info-ticks-played-help =
    .title = 遊戲建立後模擬的累計刻數，包含遊戲時刻暫停期間所處理的刻數。
map-info-game-version = 遊戲版本
map-info-mods = MOD
map-info-mods-count = { $count } 個 MOD
map-info-close = 關閉

## Share
share-x =
    .title = 分享至 X
share-bluesky =
    .title = 分享至 Bluesky
share-reddit =
    .title = 分享至 Reddit
share-copy-link =
    .title = 複製連結

### Avatar
avatar-change = 變更
avatar-remove = 移除
avatar-cancel = 取消
avatar-dismiss = 關閉
avatar-error-too-large-file-size = 檔案大小不得超過 5 MiB。
avatar-error-too-small-pixel-size = 圖片尺寸必須為 { $min }×{ $min } 像素以上。
avatar-error-too-large-pixel-size = 圖片尺寸必須為 { $max }×{ $max } 像素以下。
avatar-error-read = 無法讀取圖片。
avatar-error-remove-http = 移除頭像失敗（HTTP { $status }）。
avatar-error-network = 網路錯誤，請再試一次。
avatar-error-url-http = 無法取得上傳網址（HTTP { $status }）。
avatar-error-upload-http = 上傳失敗（HTTP { $status }）。
avatar-error-upload-network = 上傳時發生網路錯誤。
