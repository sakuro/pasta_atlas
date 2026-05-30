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
surface-nauvis = 新地星
surface-vulcanus = 伏尔卡努斯
surface-gleba = 格莱巴
surface-fulgora = 富尔格拉
surface-aquilo = 阿奎罗

## Nav
nav-log-out = 退出登录
nav-log-in = 登录
nav-log-in-discord = 通过 { -discord } 登录
nav-log-in-github = 通过 { -github } 登录
nav-log-in-steam = 通过 { -steam } 登录

## Registration
registration-title = 创建账号
registration-username = 用户名
    .help = 1–39 个字符，可使用英文字母、数字、连字符和下划线，首尾必须为英文字母或数字。
registration-submit = 创建账号

## Registration errors
error-username-empty = 请输入用户名。
error-username-too-long = 用户名不得超过 39 个字符。
error-username-invalid-chars = 用户名只能包含英文字母、数字、连字符和下划线，且首尾必须为英文字母或数字。
error-username-reserved = 该用户名已被保留。
error-username-taken = 该用户名已被占用。

## User page
user-tab-maps = 最近的地图
user-tab-profile = 个人资料
user-tab-preferences = 偏好设置
user-tab-credentials = 账号关联
user-tab-danger = 删除账户
user-tab-profile-edit =
    .title = 编辑个人资料
user-tab-preferences-edit =
    .title = 编辑偏好设置
user-connected-accounts-label = 已关联账号
provider-discord = { -discord }
provider-github = { -github }
provider-steam = { -steam }
user-timezone-label = 时区
user-locale-label = 语言

## Edit page
edit-title = 编辑
edit-avatar-label = 头像
edit-display-name = 显示名称
    .help = 最多 64 个字符，留空则显示用户名。
edit-save-profile = 保存个人资料
edit-timezone-label = 时区
edit-locale = 语言
    .use-browser = （使用浏览器设置）
edit-time-display = 时间显示
    .relative = 使用相对时间（如"3天前"）
edit-save-preferences = 保存偏好设置
edit-cancel = 取消

## Danger zone
account-delete-title = 删除账户
account-delete-warning = 此操作不可撤销。您拥有的所有地图数据也将被删除。
account-delete-confirm-label = 请输入用户名以确认：
account-delete-button = 删除我的账户

## Connected accounts
credential-connect-discord = 关联 { -discord }
credential-connect-github = 关联 { -github }
credential-connect-steam = 关联 { -steam }
credential-disconnect-discord = 取消关联 { -discord }
credential-disconnect-github = 取消关联 { -github }
credential-disconnect-steam = 取消关联 { -steam }
credential-last-hint = 至少需要一个已关联账号。

## Credential errors
error-credential-conflict = 该账号已关联至其他用户。
error-credential-last = 至少需要一个已关联账号。

## Map notices
map-deletion-requested = 您的地图已加入删除队列。可能会短暂显示一段时间。

## Map card
map-card-updated-at = { $date }

## Pagination
pagination-previous = 上一页
pagination-next = 下一页


## Upload modal
upload-button = 上传
upload-modal-title = 上传 { -mapshot }
upload-modal-title-guest = 上传 { -mapshot }（访客）
upload-instructions-folder = 请选择包含 <code data-l10n-name="filename">mapshot.json</code> 的文件夹。
upload-instructions-folder-path = { -mapshot } 的输出文件夹：
upload-copy-path-windows =
    .title = 复制路径 — 在文件夹对话框中按 Ctrl+L 粘贴
upload-copy-path-macos =
    .title = 复制路径 — 在 Finder 对话框中按 ⌘⇧G 粘贴
upload-copy-path-linux =
    .title = 复制路径 — 在文件夹对话框中按 Ctrl+L 粘贴
upload-instructions-folder-subfolder = 接着选择您的地图与世代的子文件夹：
upload-instructions-generations = 您可以上传同一张地图的不同世代。
upload-instructions-guest = 访客账号的上传在上传后无法更改地图名称。无法手动删除，约一周后会自动删除。
upload-select-folder = 选择文件夹
upload-cancel = 取消
upload-map-title = 地图标题
upload-map-name-locked =
    .title = 以访客身份上传后无法更改地图名称
upload-surfaces = 表面
upload-images = 图片数量
upload-total-size = 总大小
upload-start = 开始上传
upload-reselect-folder = 重新选择文件夹
upload-preparing = 正在准备上传...
upload-progress = 正在上传第 { $progress } / { $total } 个文件...
upload-complete = 上传完成！
upload-view-map = 查看地图
upload-close = 关闭
upload-dismiss = 关闭
upload-error-not-found = 在选择的文件夹中未找到 mapshot.json。
upload-error-parse = 无法解析 mapshot.json。
upload-error-conflict = 此世代已上传过。
upload-error-expired = 此地图已过期，无法再上传。
upload-error-http = 上传失败（HTTP { $status }）。
upload-error-network = 网络错误，请检查连接后重试。
upload-error-urls-http = 无法获取上传地址（HTTP { $status }）。
upload-error-urls-network = 获取上传地址时发生网络错误。
upload-error-file = 上传失败：{ $details }
upload-error-finalize = 图片已上传，但完成处理失败。
upload-error-finalize-network = 图片已上传，但完成处理时发生网络错误。

## How to upload modal
how-to-upload-button =
    .title = 上传说明
how-to-upload-title = 上传说明
how-to-upload-close = 关闭
how-to-upload-step1-heading = 1. 安装 { -mapshot } MOD
how-to-upload-step1-body = 从 { -factorio } 游戏内的 MOD 菜单安装 <a data-l10n-name="mapshot-link">{ -mapshot }</a>，然后重启游戏。
how-to-upload-step2-heading = 2. 截取地图
how-to-upload-step2-open-console = 打开游戏内控制台并运行：
how-to-upload-step2-wait = 截取期间游戏可能暂时无响应，请等待其恢复正常。
how-to-upload-achievement-warning = 为避免影响成就，请勿在安装 { -mapshot } 的状态下保存游戏，截取后请卸载 { -mapshot }。
how-to-upload-step3-heading = 3. 上传
how-to-upload-step3-click-upload = 点击导航栏中的"上传"。
how-to-upload-step3-select-folder = 点击"选择文件夹"并选择包含 <code data-l10n-name="filename">mapshot.json</code> 的子文件夹（请选择文件夹，而非文件本身）。
how-to-upload-step3-confirm = 确认地图标题和详细信息后，点击"开始上传"。
how-to-upload-step3-view = 上传完成后，点击"查看地图"。
how-to-upload-tip = 您可以在不同游戏刻上传同一张地图，每次上传会成为独立的世代，可在地图查看器中切换。

## Avatar upload
avatar-change = 更换
avatar-remove = 删除
avatar-cancel = 取消
avatar-dismiss = 关闭
avatar-error-too-large-file-size = 文件大小不得超过 5 MiB。
avatar-error-too-small-pixel-size = 图片尺寸必须为 { $min }×{ $min } 像素以上。
avatar-error-too-large-pixel-size = 图片尺寸必须为 { $max }×{ $max } 像素以下。
avatar-error-read = 无法读取图片。
avatar-error-remove-http = 删除头像失败（HTTP { $status }）。
avatar-error-network = 网络错误，请重试。
avatar-error-url-http = 无法获取上传地址（HTTP { $status }）。
avatar-error-upload-http = 上传失败（HTTP { $status }）。
avatar-error-upload-network = 上传时发生网络错误。

## Map viewer
map-layer-train-stations = 火车站
map-layer-tags = 标签
map-info-button =
    .title = 地图信息
map-name-edit-button =
    .title = 编辑地图名称
map-name-save-button =
    .title = 保存
map-name-cancel-button =
    .title = 取消
map-delete-button =
    .title = 删除地图
map-delete-confirm-title = 删除地图
map-delete-confirm-message = 此地图及其所有数据将被永久删除。确定吗？
map-delete-confirm-button = 删除
map-delete-cancel-button = 取消

## Map info modal
map-info-title = 地图信息
map-info-seed = 地图种子
map-info-exchange = 地图交换字符串
map-info-exchange-show =
    .title = 显示
map-info-copy =
    .title = 复制
map-info-exchange-hide =
    .title = 隐藏
map-info-tick = 刻
map-info-tick-help =
    .title = 此地图截取时的游戏内时刻。游戏暂停期间不会推进。
map-info-ticks-played = 已游玩刻数
map-info-ticks-played-help =
    .title = 游戏创建后模拟的累计刻数，包含游戏时刻暂停期间所处理的刻数。
map-info-game-version = 游戏版本
map-info-mods = MOD
map-info-mods-count = { $count } 个 MOD
map-info-close = 关闭

## Share buttons
share-x =
    .title = 分享至 X
share-bluesky =
    .title = 分享至 Bluesky
share-reddit =
    .title = 分享至 Reddit
share-copy-link =
    .title = 复制链接
nav-about = 关于
nav-privacy-policy = 隐私政策
nav-terms-of-service = 服务条款

## Registration: terms agreement
registration-terms-agree = 我同意以上内容。
