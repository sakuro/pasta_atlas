-app-name = Pasta Atlas
-discord =
    { $case ->
        [instrumental] Discordem
       *[other] Discord
    }
-github =
    { $case ->
        [instrumental] GitHubem
       *[other] GitHub
    }

## App
app-name = { -app-name }

## Surfaces
surface-nauvis = Nauvis
surface-vulcanus = Vulcanus
surface-gleba = Gleba
surface-fulgora = Fulgora
surface-aquilo = Aquilo

## Nav
nav-log-out = Odhlásit se
nav-log-in = Přihlásit se
nav-log-in-discord = Přihlásit se přes { -discord }
nav-log-in-github = Přihlásit se přes { -github }
nav-source-code = Zdrojový kód

## Registration
registration-title = Vytvořit účet
registration-username = Uživatelské jméno
    .help = 1–39 znaků. Písmena, číslice, pomlčky a podtržítka. Musí začínat a končit písmenem nebo číslicí.
registration-submit = Vytvořit účet

## Registration errors
error-username-empty = Uživatelské jméno nesmí být prázdné.
error-username-too-long = Uživatelské jméno musí mít nejvýše 39 znaků.
error-username-invalid-chars = Uživatelské jméno smí obsahovat pouze písmena, číslice, pomlčky a podtržítka a musí začínat a končit písmenem nebo číslicí.
error-username-reserved = Toto uživatelské jméno je rezervováno.
error-username-taken = Toto uživatelské jméno je již obsazeno.

## User page
user-tab-profile = Profil
user-tab-preferences = Nastavení
user-tab-profile-edit =
    .title = Upravit profil
user-tab-preferences-edit =
    .title = Upravit nastavení
user-recent-maps = Nedávné mapy
user-connected-accounts-label = Propojené účty
provider-discord = { -discord }
provider-github = { -github }
user-timezone-label = Časové pásmo
user-locale-label = Jazyk

## Edit page
edit-title = Upravit
edit-avatar-label = Avatar
edit-display-name = Zobrazované jméno
    .help = Až 64 znaků. Ponechte prázdné pro použití uživatelského jména.
edit-save-profile = Uložit profil
edit-timezone-label = Časové pásmo
edit-locale = Jazyk
    .not-set = (nenastaveno)
edit-save-preferences = Uložit nastavení
edit-cancel = Zrušit

## Connected accounts
credential-connect-discord = Propojit s { -discord(case: "instrumental") }
credential-connect-github = Propojit s { -github(case: "instrumental") }
credential-disconnect-discord = Odpojit { -discord }
credential-disconnect-github = Odpojit { -github }
credential-last-hint = Je vyžadován alespoň jeden propojený účet.

## Credential errors
error-credential-conflict = Tento účet je již propojen s jiným uživatelem.
error-credential-last = Je vyžadován alespoň jeden propojený účet.

## Map card
map-card-updated-at = { $date }

## Pagination
pagination-previous = Předchozí
pagination-next = Další


## Upload modal
upload-button = Nahrát
upload-modal-title = Nahrát Mapshot
upload-instructions-folder = Vyberte složku obsahující mapshot.json.
upload-instructions-folder-path = Typická složka Mapshot:
upload-instructions-generations = Můžete nahrát různé generace existující mapy.
upload-instructions-guest = Nahrávky z hostovských účtů jsou po přibližně jednom týdnu smazány.
upload-select-folder = Vybrat složku
upload-cancel = Zrušit
upload-map-title = Název mapy
upload-surfaces = Povrchy
upload-images = Obrázky
upload-total-size = Celková velikost
upload-start = Zahájit nahrávání
upload-back = Zpět
upload-progress = Nahrávám { $progress } / { $total } souborů...
upload-complete = Nahrávání dokončeno!
upload-view-map = Zobrazit mapu
upload-close = Zavřít
upload-dismiss = Zavřít
upload-error-not-found = Soubor mapshot.json nebyl ve vybrané složce nalezen.
upload-error-parse = Nepodařilo se načíst mapshot.json.
upload-error-conflict = Tato generace již byla nahrána.
upload-error-http = Nahrávání selhalo (HTTP { $status }).
upload-error-network = Chyba sítě. Zkontrolujte prosím připojení a zkuste to znovu.
upload-error-urls-http = Nepodařilo se získat URL pro nahrávání (HTTP { $status }).
upload-error-urls-network = Chyba sítě při získávání URL pro nahrávání.
upload-error-file = Nahrávání selhalo: { $details }
upload-error-finalize = Obrázky byly nahrány, ale dokončení selhalo.
upload-error-finalize-network = Obrázky byly nahrány, ale při dokončení došlo k chybě sítě.

## Avatar upload
avatar-change = Změnit
avatar-remove = Odebrat
avatar-cancel = Zrušit
avatar-dismiss = Zavřít
avatar-error-too-large-file-size = Soubor musí být menší nebo roven 5 MiB.
avatar-error-too-small-pixel-size = Obrázek musí být alespoň { $min }×{ $min } pixelů.
avatar-error-too-large-pixel-size = Obrázek musí být nejvýše { $max }×{ $max } pixelů.
avatar-error-read = Nepodařilo se načíst obrázek.
avatar-error-remove-http = Nepodařilo se odebrat avatar (HTTP { $status }).
avatar-error-network = Chyba sítě. Zkuste to prosím znovu.
avatar-error-url-http = Nepodařilo se získat URL pro nahrávání (HTTP { $status }).
avatar-error-upload-http = Nahrávání selhalo (HTTP { $status }).
avatar-error-upload-network = Při nahrávání došlo k chybě sítě.

## Map viewer
map-layer-train-stations = Vlakové stanice
map-layer-tags = Značky
map-info-button =
    .title = Informace o mapě

## Map info modal
map-info-title = Informace o mapě
map-info-seed = Seed mapy
map-info-exchange = Výměnný řetězec mapy
map-info-exchange-show =
    .title = Zobrazit
map-info-copy =
    .title = Kopírovat
map-info-exchange-hide =
    .title = Skrýt
map-info-tick = Tik
map-info-ticks-played = Odehraných tiků
map-info-game-version = Verze hry
map-info-mods = Mody
map-info-mods-count =
    { $count ->
        [one] { $count } mod
        [few] { $count } mody
       *[other] { $count } modů
    }
map-info-close = Zavřít

## Share buttons
share-x =
    .title = Sdílet na X
share-bluesky =
    .title = Sdílet na Bluesky
share-reddit =
    .title = Sdílet na Reddit
share-copy-link =
    .title = Kopírovat odkaz
