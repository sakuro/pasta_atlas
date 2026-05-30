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
surface-nauvis = 나우비스
surface-vulcanus = 불카누스
surface-gleba = 글레바
surface-fulgora = 풀고라
surface-aquilo = 아퀼로

## Nav
nav-log-out = 로그아웃
nav-log-in = 로그인
nav-log-in-discord = { -discord }로 로그인
nav-log-in-github = { -github }로 로그인
nav-log-in-steam = { -steam }으로 로그인

## Registration
registration-title = 계정 만들기
registration-username = 사용자 이름
    .help = 1~39자. 영문자, 숫자, 하이픈, 밑줄을 사용할 수 있습니다. 첫 글자와 마지막 글자는 영문자 또는 숫자여야 합니다.
registration-submit = 계정 만들기

## Registration errors
error-username-empty = 사용자 이름을 입력해 주세요.
error-username-too-long = 사용자 이름은 39자 이하여야 합니다.
error-username-invalid-chars = 사용자 이름에는 영문자, 숫자, 하이픈, 밑줄만 사용할 수 있으며, 첫 글자와 마지막 글자는 영문자 또는 숫자여야 합니다.
error-username-reserved = 해당 사용자 이름은 사용할 수 없습니다.
error-username-taken = 해당 사용자 이름은 이미 사용 중입니다.

## User page
user-tab-maps = 최근 맵
user-tab-profile = 프로필
user-tab-preferences = 설정
user-tab-credentials = 계정 연결
user-tab-danger = 계정 삭제
user-tab-profile-edit =
    .title = 프로필 편집
user-tab-preferences-edit =
    .title = 설정 편집
user-connected-accounts-label = 연결된 계정
provider-discord = { -discord }
provider-github = { -github }
provider-steam = { -steam }
user-timezone-label = 시간대
user-locale-label = 언어

## Edit page
edit-title = 편집
edit-avatar-label = 아바타
edit-display-name = 표시 이름
    .help = 최대 64자. 비워 두면 사용자 이름이 표시됩니다.
edit-save-profile = 프로필 저장
edit-timezone-label = 시간대
edit-locale = 언어
    .use-browser = (브라우저 설정 사용)
edit-locale-use-browser = (브라우저 설정 사용)
edit-time-display = 시간 표시
    .relative = 상대 시간으로 표시 (예: "3일 전")
edit-time-display-relative = 상대 시간으로 표시 (예: "3일 전")
edit-save-preferences = 설정 저장
edit-cancel = 취소

## Danger zone
account-delete-title = 계정 삭제
account-delete-warning = 이 작업은 되돌릴 수 없습니다. 소유한 모든 지도 데이터도 삭제됩니다.
account-delete-confirm-label = 확인을 위해 사용자 이름을 입력하세요:
account-delete-button = 내 계정 삭제

## Connected accounts
credential-connect-discord = { -discord }로 연결
credential-connect-github = { -github }로 연결
credential-connect-steam = { -steam }으로 연결
credential-disconnect-discord = { -discord } 연결 해제
credential-disconnect-github = { -github } 연결 해제
credential-disconnect-steam = { -steam } 연결 해제
credential-last-hint = 최소 하나의 연결된 계정이 필요합니다.

## Credential errors
error-credential-conflict = 해당 계정은 이미 다른 사용자에게 연결되어 있습니다.
error-credential-last = 최소 하나의 연결된 계정이 필요합니다.

## Map notices
map-deletion-requested = 맵이 삭제 대기열에 추가되었습니다. 잠시 동안 표시될 수 있습니다.

## Map card
map-card-updated-at = { $date }

## Pagination
pagination-previous = 이전
pagination-next = 다음


## Upload modal
upload-button = 업로드
upload-modal-title = { -mapshot } 업로드
upload-modal-title-guest = { -mapshot } 업로드 (게스트로)
upload-instructions-folder = <code data-l10n-name="filename">mapshot.json</code>이 포함된 폴더를 선택해 주세요.
upload-instructions-folder-path = { -mapshot } 출력 폴더:
upload-copy-path-windows =
    .title = 경로 복사 — 폴더 대화상자에서 Ctrl+L을 눌러 붙여넣기
upload-copy-path-macos =
    .title = 경로 복사 — Finder 대화상자에서 ⌘⇧G를 눌러 붙여넣기
upload-copy-path-linux =
    .title = 경로 복사 — 폴더 대화상자에서 Ctrl+L을 눌러 붙여넣기
upload-instructions-folder-subfolder = 이어서 맵과 세대의 하위 폴더를 선택해 주세요:
upload-instructions-generations = 기존 맵의 다른 세대도 업로드할 수 있습니다.
upload-instructions-guest = 게스트 계정의 업로드는 업로드 후 맵 이름을 변경할 수 없습니다. 수동으로 삭제할 수 없으며, 약 1주일 후에 자동으로 삭제됩니다.
upload-select-folder = 폴더 선택
upload-cancel = 취소
upload-map-title = 맵 제목
upload-map-name-locked =
    .title = 게스트로 업로드한 후에는 맵 이름을 변경할 수 없습니다
upload-surfaces = 서피스
upload-images = 이미지 수
upload-total-size = 전체 크기
upload-start = 업로드 시작
upload-reselect-folder = 폴더 다시 선택
upload-preparing = 업로드 준비 중...
upload-progress = { $progress } / { $total } 파일 업로드 중...
upload-complete = 업로드 완료!
upload-view-map = 맵 보기
upload-close = 닫기
upload-dismiss = 닫기
upload-error-not-found = 선택한 폴더에서 mapshot.json을 찾을 수 없습니다.
upload-error-parse = mapshot.json을 파싱하는 데 실패했습니다.
upload-error-conflict = 이 세대는 이미 업로드되었습니다.
upload-error-expired = 이 맵은 만료되어 더 이상 업로드할 수 없습니다.
upload-error-http = 업로드에 실패했습니다(HTTP { $status }).
upload-error-network = 네트워크 오류가 발생했습니다. 연결을 확인하고 다시 시도해 주세요.
upload-error-urls-http = 업로드 URL을 가져오는 데 실패했습니다(HTTP { $status }).
upload-error-urls-network = 업로드 URL을 가져오는 중 네트워크 오류가 발생했습니다.
upload-error-file = 업로드에 실패했습니다: { $details }
upload-error-finalize = 이미지 업로드는 완료되었지만 마무리 처리에 실패했습니다.
upload-error-finalize-network = 이미지 업로드는 완료되었지만 마무리 처리 중 네트워크 오류가 발생했습니다.

## How to upload modal
how-to-upload-button =
    .title = 업로드 방법
how-to-upload-title = 업로드 방법
how-to-upload-close = 닫기
how-to-upload-step1-heading = 1. { -mapshot } MOD 설치
how-to-upload-step1-body = { -factorio } 게임 내 MOD 메뉴에서 <a data-l10n-name="mapshot-link">{ -mapshot }</a>을 설치하고 게임을 재시작하세요.
how-to-upload-step2-heading = 2. 맵 캡처
how-to-upload-step2-open-console = 게임 내 콘솔을 열고 다음 명령어를 실행하세요:
how-to-upload-step2-wait = 캡처 중에는 게임이 잠시 응답하지 않을 수 있습니다 — 정상으로 돌아올 때까지 기다려 주세요.
how-to-upload-achievement-warning = 업적에 영향을 주지 않으려면 { -mapshot }이 설치된 상태에서 게임을 저장하지 마세요. 캡처 후 { -mapshot }을 제거하세요.
how-to-upload-step3-heading = 3. 업로드
how-to-upload-step3-click-upload = 내비게이션 바에서 "업로드"를 클릭하세요.
how-to-upload-step3-select-folder = "폴더 선택"을 클릭하고 <code data-l10n-name="filename">mapshot.json</code>이 포함된 하위 폴더를 선택하세요(파일 자체가 아닌 폴더를 선택하세요).
how-to-upload-step3-confirm = 맵 제목과 세부 정보를 확인한 후 "업로드 시작"을 클릭하세요.
how-to-upload-step3-view = 업로드가 완료되면 "맵 보기"를 클릭하세요.
how-to-upload-tip = 같은 맵을 다른 게임 틱에서 업로드할 수 있습니다. 각 업로드는 별도의 세대가 되며 맵 뷰어에서 전환할 수 있습니다.

## Avatar upload
avatar-change = 변경
avatar-remove = 삭제
avatar-cancel = 취소
avatar-dismiss = 닫기
avatar-error-too-large-file-size = 파일 크기는 5 MiB 이하여야 합니다.
avatar-error-too-small-pixel-size = 이미지는 { $min }×{ $min } 픽셀 이상이어야 합니다.
avatar-error-too-large-pixel-size = 이미지는 { $max }×{ $max } 픽셀 이하여야 합니다.
avatar-error-read = 이미지를 읽는 데 실패했습니다.
avatar-error-remove-http = 아바타를 삭제하는 데 실패했습니다(HTTP { $status }).
avatar-error-network = 네트워크 오류가 발생했습니다. 다시 시도해 주세요.
avatar-error-url-http = 업로드 URL을 가져오는 데 실패했습니다(HTTP { $status }).
avatar-error-upload-http = 업로드에 실패했습니다(HTTP { $status }).
avatar-error-upload-network = 업로드 중 네트워크 오류가 발생했습니다.

## Map viewer
map-layer-train-stations = 기차역
map-layer-tags = 태그
map-info-button =
    .title = 맵 정보
map-name-edit-button =
    .title = 맵 이름 편집
map-name-save-button =
    .title = 저장
map-name-cancel-button =
    .title = 취소
map-delete-button =
    .title = 맵 삭제
map-delete-confirm-title = 맵 삭제
map-delete-confirm-message = 이 맵과 모든 데이터가 영구적으로 삭제됩니다. 계속하시겠습니까?
map-delete-confirm-button = 삭제
map-delete-cancel-button = 취소

## Map info modal
map-info-title = 맵 정보
map-info-seed = 맵 시드
map-info-exchange = 맵 교환 문자열
map-info-exchange-show =
    .title = 표시
map-info-copy =
    .title = 복사
map-info-exchange-hide =
    .title = 숨기기
map-info-tick = 틱
map-info-tick-help =
    .title = 이 맵이 캡처된 시점의 게임 내 시각. 게임이 일시 정지된 동안에는 진행되지 않음.
map-info-ticks-played = 플레이 틱 수
map-info-ticks-played-help =
    .title = 게임이 생성된 이후 시뮬레이션된 총 틱 수. 게임 시각이 정지된 상태에서 처리된 틱도 포함.
map-info-game-version = 게임 버전
map-info-mods = MOD
map-info-mods-count = MOD { $count }개
map-info-close = 닫기

## Share buttons
share-x =
    .title = X에 공유
share-bluesky =
    .title = Bluesky에 공유
share-reddit =
    .title = Reddit에 공유
share-copy-link =
    .title = 링크 복사
nav-about = 소개
nav-privacy-policy = 개인정보 처리방침
nav-terms-of-service = 이용약관

## Registration: terms agreement
registration-terms-agree = 위 내용에 동의합니다.
