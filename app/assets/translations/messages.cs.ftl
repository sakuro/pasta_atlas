-app-name = Pasta Atlas
-mapshot =
    { $case ->
        [accusative] Mapshot
        [genitive] Mapshotu
       *[other] Mapshot
    }
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
-steam =
    { $case ->
        [instrumental] Steamem
       *[other] Steam
    }
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
nav-log-out = Odhlásit se
nav-log-in = Přihlásit se
nav-log-in-discord = Přihlásit se přes { -discord }
nav-log-in-github = Přihlásit se přes { -github }
nav-log-in-steam = Přihlásit se přes { -steam }

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
user-tab-maps = Nedávné mapy
user-tab-profile = Profil
user-tab-preferences = Nastavení
user-tab-credentials = Propojené účty
user-tab-danger = Smazat účet
user-tab-profile-edit =
    .title = Upravit profil
user-tab-preferences-edit =
    .title = Upravit nastavení
user-connected-accounts-label = Propojené účty
provider-discord = { -discord }
provider-github = { -github }
provider-steam = { -steam }
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
    .use-browser = (Podle prohlížeče)
edit-time-display = Zobrazení času
    .relative = Zobrazovat relativní čas (např. „před 3 dny")
edit-save-preferences = Uložit nastavení
edit-cancel = Zrušit

## Danger zone
account-delete-title = Smazat účet
account-delete-warning = Tato akce je nevratná. Všechny vaše mapy budou také smazány.
account-delete-confirm-label = Pro potvrzení zadejte své uživatelské jméno:
account-delete-button = Smazat můj účet

## Connected accounts
credential-connect-discord = Propojit s { -discord(case: "instrumental") }
credential-connect-github = Propojit s { -github(case: "instrumental") }
credential-connect-steam = Propojit se { -steam(case: "instrumental") }
credential-disconnect-discord = Odpojit { -discord }
credential-disconnect-github = Odpojit { -github }
credential-disconnect-steam = Odpojit { -steam }
credential-last-hint = Je vyžadován alespoň jeden propojený účet.

## Credential errors
error-credential-conflict = Tento účet je již propojen s jiným uživatelem.
error-credential-last = Je vyžadován alespoň jeden propojený účet.

## Map notices
map-deletion-requested = Vaše mapa byla zařazena do fronty k odstranění. Může být ještě chvíli viditelná.

## Map card
map-card-updated-at = { $date }

## Pagination
pagination-previous = Předchozí
pagination-next = Další


## Upload modal
upload-button = Nahrát
upload-modal-title = Nahrát { -mapshot(case: "accusative") }
upload-modal-title-guest = Nahrát { -mapshot(case: "accusative") } (jako host)
upload-instructions-folder = Vyberte složku obsahující <code data-l10n-name="filename">mapshot.json</code>.
upload-instructions-folder-path = Výstupní složka { -mapshot(case: "genitive") }:
upload-copy-path-windows =
    .title = Kopírovat cestu — vložit v dialogu složky (Ctrl+L)
upload-copy-path-macos =
    .title = Kopírovat cestu — vložit v dialogu Finderu (⌘⇧G)
upload-copy-path-linux =
    .title = Kopírovat cestu — vložit v dialogu složky (Ctrl+L)
upload-instructions-folder-subfolder = Poté vyberte podsložku pro vaši mapu a generaci:
upload-instructions-generations = Můžete nahrát různé generace existující mapy.
upload-instructions-guest = U nahrávek z hostovských účtů nelze název mapy po nahrání změnit. Nelze je ručně smazat a jsou automaticky smazány přibližně po jednom týdnu.
upload-select-folder = Vybrat složku
upload-cancel = Zrušit
upload-map-title = Název mapy
upload-map-name-locked =
    .title = Název mapy nelze po nahrání jako host změnit
upload-surfaces = Povrchy
upload-images = Obrázky
upload-total-size = Celková velikost
upload-start = Zahájit nahrávání
upload-reselect-folder = Změnit složku
upload-preparing = Připravuji nahrávání...
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

## Modální okno – jak nahrát
how-to-upload-button =
    .title = Jak nahrát
how-to-upload-title = Jak nahrát
how-to-upload-close = Zavřít
how-to-upload-step1-heading = 1. Nainstalujte mod { -mapshot }
how-to-upload-step1-body = Nainstalujte <a data-l10n-name="mapshot-link">{ -mapshot(case: "accusative") }</a> z herního menu Modů a restartujte hru.
how-to-upload-step2-heading = 2. Zachyťte svou mapu
how-to-upload-step2-open-console = Otevřete herní konzoli a spusťte:
how-to-upload-step2-wait = Během snímání hra dočasně přestane reagovat — počkejte, dokud se nevrátí do normálního stavu.
how-to-upload-achievement-warning = Chcete-li se vyhnout ovlivnění úspěchů, neukládejte hru, pokud máte { -mapshot } nainstalovaný. Po snímání { -mapshot(case: "accusative") } odinstalujte.
how-to-upload-step3-heading = 3. Nahrajte
how-to-upload-step3-click-upload = Klikněte na „Nahrát" v navigační liště.
how-to-upload-step3-select-folder = Klikněte na „Vybrat složku" a vyberte podsložku obsahující <code data-l10n-name="filename">mapshot.json</code> (ne samotný soubor).
how-to-upload-step3-confirm = Potvrďte název mapy a detaily, poté klikněte na „Zahájit nahrávání".
how-to-upload-step3-view = Po dokončení nahrávání klikněte na „Zobrazit mapu".
how-to-upload-tip = Stejnou mapu můžete nahrát při různých herních ticích — každé nahrání vytvoří samostatnou generaci, mezi nimiž lze přepínat v prohlížeči map.

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
map-layer-train-stations = Železniční zastávky
map-layer-tags = Štítky
map-info-button =
    .title = Informace o mapě
map-name-edit-button =
    .title = Upravit název mapy
map-name-save-button =
    .title = Uložit
map-name-cancel-button =
    .title = Zrušit
map-delete-button =
    .title = Smazat mapu
map-delete-confirm-title = Smazat mapu
map-delete-confirm-message = Tato mapa a všechna její data budou trvale smazána. Jste si jisti?
map-delete-confirm-button = Smazat
map-delete-cancel-button = Zrušit

## Map info modal
map-info-title = Informace o mapě
map-info-seed = Kód mapy
map-info-exchange = Řetězec pro výměnu map
map-info-exchange-show =
    .title = Zobrazit
map-info-copy =
    .title = Kopírovat
map-info-exchange-hide =
    .title = Skrýt
map-info-tick = Tik
map-info-tick-help =
    .title = Herní čas v okamžiku pořízení tohoto snímku. Nepokračuje, dokud je hra pozastavena.
map-info-ticks-played = Odehraných tiků
map-info-ticks-played-help =
    .title = Celkový počet simulovaných tiků od vytvoření hry, včetně tiků zpracovaných během pozastavení herního času.
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
nav-about = O službě
nav-privacy-policy = Zásady ochrany osobních údajů
nav-terms-of-service = Podmínky služby

## Registration: terms agreement
registration-terms-agree = Souhlasím s výše uvedeným.
