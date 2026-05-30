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
surface-nauvis = ナウヴィス
surface-vulcanus = ヴルカヌス
surface-gleba = グレバ
surface-fulgora = フルゴラ
surface-aquilo = アクィロ

## Nav
nav-log-out = ログアウト
nav-log-in = ログイン
nav-log-in-discord = { -discord } でログイン
nav-log-in-github = { -github } でログイン
nav-log-in-steam = { -steam } でログイン

## Registration
registration-title = アカウントを作成
registration-username = ユーザー名
    .help = 1〜39文字。英数字・ハイフン・アンダースコアが使用できます。先頭と末尾は英数字にしてください。
registration-submit = アカウントを作成する

## Registration errors
error-username-empty = ユーザー名を入力してください。
error-username-too-long = ユーザー名は39文字以内にしてください。
error-username-invalid-chars = ユーザー名には英数字・ハイフン・アンダースコアのみ使用でき、先頭と末尾は英数字にしてください。
error-username-reserved = そのユーザー名は使用できません。
error-username-taken = そのユーザー名はすでに使われています。

## User page
user-tab-maps = 最近のマップ
user-tab-profile = プロフィール
user-tab-preferences = 設定
user-tab-credentials = アカウント連携
user-tab-danger = アカウント削除
user-tab-profile-edit =
    .title = プロフィールを編集
user-tab-preferences-edit =
    .title = 設定を編集
user-connected-accounts-label = 連携済アカウント
provider-discord = { -discord }
provider-github = { -github }
provider-steam = { -steam }
user-timezone-label = タイムゾーン
user-locale-label = 言語

## Edit page
edit-title = 編集
edit-avatar-label = アバター
edit-display-name = 表示名
    .help = 64文字以内。空白にするとユーザー名が表示されます。
edit-save-profile = プロフィールを保存
edit-timezone-label = タイムゾーン
edit-locale = 言語
    .use-browser = (ブラウザに従う)
edit-time-display = 時刻表示
    .relative = 相対時刻で表示する（例：「3日前」）
edit-save-preferences = 設定を保存
edit-cancel = キャンセル

## Danger zone
account-delete-title = アカウントを削除する
account-delete-warning = この操作は取り消せません。所有する全ての地図データも削除されます。
account-delete-confirm-label = ユーザー名を入力して確認してください:
account-delete-button = アカウントを削除する

## Connected accounts
credential-connect-discord = { -discord } と連携する
credential-connect-github = { -github } と連携する
credential-connect-steam = { -steam } と連携する
credential-disconnect-discord = { -discord } の連携を解除
credential-disconnect-github = { -github } の連携を解除
credential-disconnect-steam = { -steam } の連携を解除
credential-last-hint = 少なくとも1つの連携済アカウントが必要です。

## Credential errors
error-credential-conflict = そのアカウントはすでに別のユーザーに連携されています。
error-credential-last = 少なくとも1つの連携済アカウントが必要です。

## Map notices
map-deletion-requested = マップの削除をリクエストしました。しばらく表示されたままになることがあります。

## Map card
map-card-updated-at = { $date }

## Pagination
pagination-previous = 前へ
pagination-next = 次へ


## Upload modal
upload-button = アップロード
upload-modal-title = { -mapshot } をアップロード
upload-modal-title-guest = { -mapshot } をアップロード（ゲストとして）
upload-instructions-folder = <code data-l10n-name="filename">mapshot.json</code> を含むフォルダーを選択してください。
upload-instructions-folder-path = { -mapshot } の出力フォルダー:
upload-copy-path-windows =
    .title = パスをコピー — フォルダーダイアログで Ctrl+L を押して貼り付け
upload-copy-path-macos =
    .title = パスをコピー — Finder ダイアログで ⌘⇧G を押して貼り付け
upload-copy-path-linux =
    .title = パスをコピー — フォルダーダイアログで Ctrl+L を押して貼り付け
upload-instructions-folder-subfolder = 続いてマップと世代のサブフォルダーを選択してください:
upload-instructions-generations = 既存マップの異なる世代もアップロードできます。
upload-instructions-guest = ゲストアカウントのアップロードは、アップロード後にマップ名を変更できません。手動では削除できず、約 1 週間後に自動的に削除されます。
upload-select-folder = フォルダーを選択
upload-cancel = キャンセル
upload-map-title = マップタイトル
upload-surfaces = サーフィス
upload-images = 画像数
upload-total-size = 合計サイズ
upload-start = アップロード開始
upload-reselect-folder = フォルダーを選び直す
upload-preparing = アップロードの準備中...
upload-progress = { $progress } / { $total } ファイルをアップロード中...
upload-complete = アップロード完了！
upload-view-map = マップを表示
upload-close = 閉じる
upload-dismiss = 閉じる
upload-error-not-found = 選択したフォルダーに mapshot.json が見つかりませんでした。
upload-error-parse = mapshot.json の解析に失敗しました。
upload-error-conflict = この世代はすでにアップロード済みです。
upload-error-http = アップロードに失敗しました(HTTP { $status })。
upload-error-network = ネットワークエラー。接続を確認してください。
upload-error-urls-http = アップロード URL の取得に失敗しました(HTTP { $status })。
upload-error-urls-network = アップロード URL の取得中にネットワークエラーが発生しました。
upload-error-file = アップロードに失敗しました: { $details }
upload-error-finalize = 画像のアップロードは完了しましたが、完了処理に失敗しました。
upload-error-finalize-network = 画像のアップロードは完了しましたが、完了処理中にネットワークエラーが発生しました。

## How to upload モーダル
how-to-upload-button =
    .title = アップロード方法
how-to-upload-title = アップロード方法
how-to-upload-close = 閉じる
how-to-upload-step1-heading = 1. { -mapshot } MOD を導入する
how-to-upload-step1-body = { -factorio } のゲーム内 MOD メニューから <a data-l10n-name="mapshot-link">{ -mapshot }</a> をインストールし、ゲームを再起動してください。
how-to-upload-step2-heading = 2. マップを撮影する
how-to-upload-step2-open-console = ゲーム内コンソールを開き、次のコマンドを実行してください:
how-to-upload-step2-wait = 撮影中はゲームが一時的に応答しなくなります — 完了するまでお待ちください。
how-to-upload-achievement-warning = 実績への影響を避けたい場合は、{ -mapshot } を導入した状態でゲームデータを保存せず、撮影後にアンインストールしてください。
how-to-upload-step3-heading = 3. アップロードする
how-to-upload-step3-click-upload = ナビゲーションバーの「アップロード」をクリックします。
how-to-upload-step3-select-folder = 「フォルダーを選択」をクリックし、<code data-l10n-name="filename">mapshot.json</code> を含むサブフォルダーを選択します（ファイル自体ではなくフォルダーを選択してください）。
how-to-upload-step3-confirm = マップタイトルと内容を確認し、「アップロード開始」をクリックします。
how-to-upload-step3-view = アップロードが完了したら「マップを表示」をクリックします。
how-to-upload-tip = 同じマップを異なるゲームティックでアップロードできます。各アップロードは個別の「世代」となり、マップビューアーで切り替えられます。

## Avatar upload
avatar-change = 変更
avatar-remove = 削除
avatar-cancel = キャンセル
avatar-dismiss = 閉じる
avatar-error-too-large-file-size = ファイルサイズは 5 MiB 以下にしてください。
avatar-error-too-small-pixel-size = 画像は { $min }×{ $min } ピクセル以上にしてください。
avatar-error-too-large-pixel-size = 画像は { $max }×{ $max } ピクセル以下にしてください。
avatar-error-read = 画像の読み込みに失敗しました。
avatar-error-remove-http = アバターの削除に失敗しました(HTTP { $status })。
avatar-error-network = ネットワークエラー。再度お試しください。
avatar-error-url-http = アップロード URL の取得に失敗しました(HTTP { $status })。
avatar-error-upload-http = アップロードに失敗しました(HTTP { $status })。
avatar-error-upload-network = アップロード中にネットワークエラーが発生しました。

## Map viewer
map-layer-train-stations = 列車の駅
map-layer-tags = タグ
map-info-button =
    .title = マップ情報
map-name-edit-button =
    .title = マップ名を編集
map-name-save-button =
    .title = 保存
map-name-cancel-button =
    .title = キャンセル
map-delete-button =
    .title = マップを削除
map-delete-confirm-title = マップを削除
map-delete-confirm-message = このマップとすべてのデータが完全に削除されます。よろしいですか？
map-delete-confirm-button = 削除
map-delete-cancel-button = キャンセル

## Map info modal
map-info-title = マップ情報
map-info-seed = マップシード
map-info-exchange = マップ交換文字列
map-info-exchange-show =
    .title = 表示
map-info-copy =
    .title = コピー
map-info-exchange-hide =
    .title = 非表示
map-info-tick = 撮影ティック
map-info-tick-help =
    .title = マップ撮影時のゲーム内時刻。ゲームが一時停止中は進まない。
map-info-ticks-played = 経過ティック数
map-info-ticks-played-help =
    .title = ゲーム作成からシミュレートされた累計ティック数。ゲーム内時刻が停止中に処理されたティックも含む。
map-info-game-version = ゲームバージョン
map-info-mods = MOD
map-info-mods-count = { $count } 個の MOD
map-info-close = 閉じる

## Share buttons
share-x =
    .title = X でシェア
share-bluesky =
    .title = Bluesky でシェア
share-reddit =
    .title = Reddit でシェア
share-copy-link =
    .title = リンクをコピー
nav-about = このサイトについて
nav-privacy-policy = プライバシーポリシー
nav-terms-of-service = 利用規約

## Registration: terms agreement
registration-terms-agree = 上記に同意します。
